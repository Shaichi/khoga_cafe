package com.khoga.pos;

import com.khoga.common.exception.AppException;
import com.khoga.common.exception.ResourceNotFoundException;
import com.khoga.common.model.Order;
import com.khoga.common.model.ShiftSession;
import com.khoga.common.model.Store;
import com.khoga.common.model.User;
import com.khoga.common.model.enums.OrderStatus;
import com.khoga.common.model.enums.PaymentMethod;
import com.khoga.common.model.enums.PaymentStatus;
import com.khoga.common.model.enums.RefundType;
import com.khoga.common.model.enums.Role;
import com.khoga.common.model.enums.ShiftStatus;
import com.khoga.common.repository.OrderRefundRepository;
import com.khoga.common.repository.OrderRepository;
import com.khoga.common.repository.ShiftSessionRepository;
import com.khoga.common.repository.UserRepository;
import com.khoga.integration.EmailService;
import com.khoga.pos.dto.OpenShiftRequest;
import com.khoga.pos.dto.ShiftResponse;
import com.khoga.pos.dto.ZReportResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Shift lifecycle (UC-44 open, UC-53 close) and cash reconciliation. One OPEN shift per register per
 * branch (BR-92); opening float ≥ 0 (BR-33). Close force-abandons uncollected READY orders (BR-88) then
 * blocks while any PENDING/PREPARING/HOLD order remains (BR-03); a cash discrepancy over 100,000 VND is
 * flagged and the Store Manager emailed (BR-04). {@code ShiftAutoCloseScheduler} calls {@link #autoClose}.
 */
@Slf4j
@Service
public class ShiftService {

    private static final BigDecimal DISCREPANCY_THRESHOLD = new BigDecimal("100000");
    private static final List<OrderStatus> BLOCKING =
            List.of(OrderStatus.PENDING, OrderStatus.PREPARING, OrderStatus.HOLD, OrderStatus.READY);

    private final ShiftSessionRepository shiftSessionRepository;
    private final OrderRepository orderRepository;
    private final OrderRefundRepository orderRefundRepository;
    private final UserRepository userRepository;
    private final EmailService emailService;

    public ShiftService(ShiftSessionRepository shiftSessionRepository, OrderRepository orderRepository,
                        OrderRefundRepository orderRefundRepository, UserRepository userRepository,
                        EmailService emailService) {
        this.shiftSessionRepository = shiftSessionRepository;
        this.orderRepository = orderRepository;
        this.orderRefundRepository = orderRefundRepository;
        this.userRepository = userRepository;
        this.emailService = emailService;
    }

    @Transactional
    public ShiftResponse openShift(OpenShiftRequest req, UUID actorId) {
        User user = currentUser(actorId);
        Store store = user.getStore();
        if (req.startingCash().signum() < 0) {
            throw AppException.of("err.050"); // BR-33
        }
        if (shiftSessionRepository.existsByStoreIdAndPosRegisterIdAndStatus(
                store.getId(), req.posRegisterId(), ShiftStatus.OPEN)) {
            throw AppException.of("err.051"); // BR-92
        }
        ShiftSession session = new ShiftSession();
        session.setStore(store);
        session.setUser(user);
        session.setPosRegisterId(req.posRegisterId());
        session.setStartingCash(req.startingCash());
        session.setStatus(ShiftStatus.OPEN);
        session.setStartTime(LocalDateTime.now());
        return toResponse(shiftSessionRepository.save(session));
    }

    @Transactional(readOnly = true)
    public ShiftResponse getActiveShift(UUID actorId) {
        ShiftSession session = shiftSessionRepository.findFirstByUserIdAndStatus(actorId, ShiftStatus.OPEN)
                .orElseThrow(() -> new ResourceNotFoundException("Không có ca đang mở"));
        return toResponse(session);
    }

    @Transactional
    public ZReportResponse closeShift(UUID sessionId, BigDecimal closingCash, String discrepancyNotes, UUID actorId) {
        User user = currentUser(actorId);
        ShiftSession session = shiftSessionRepository.findById(sessionId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy ca"));
        if (session.getStatus() != ShiftStatus.OPEN) {
            throw AppException.of("err.052");
        }
        if (session.getStore() == null || !session.getStore().getId().equals(user.getStore().getId())) {
            throw AppException.of("err.053");
        }
        return reconcileAndClose(session, closingCash, discrepancyNotes);
    }

    @Transactional(readOnly = true)
    public ZReportResponse previewClose(UUID sessionId, UUID actorId) {
        User user = currentUser(actorId);
        ShiftSession session = shiftSessionRepository.findById(sessionId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy ca"));
        if (session.getStatus() != ShiftStatus.OPEN) {
            throw AppException.of("err.052");
        }
        if (session.getStore() == null || !session.getStore().getId().equals(user.getStore().getId())) {
            throw AppException.of("err.053");
        }
        
        BigDecimal opening = nz(session.getStartingCash());
        BigDecimal totalCashSales = nz(orderRepository.sumSales(
                session.getId(), PaymentMethod.CASH, PaymentStatus.PAID));
        BigDecimal totalCardSales = nz(orderRepository.sumSales(
                session.getId(), PaymentMethod.CARD, PaymentStatus.PAID));
        BigDecimal totalVietQrSales = nz(orderRepository.sumSales(
                session.getId(), PaymentMethod.VIETQR, PaymentStatus.PAID));
        
        long totalOrders = orderRepository.countByShiftSessionId(session.getId());
        long cancelledOrders = orderRepository.countByShiftSessionIdAndStatus(session.getId(), OrderStatus.CANCELLED);

        BigDecimal refunds = nz(orderRefundRepository.sumByShiftAndType(session.getId(), RefundType.REFUND));
        BigDecimal expected = opening.add(totalCashSales).subtract(refunds);
        
        return new ZReportResponse(session.getId(), session.getPosRegisterId(), opening, totalCashSales,
                totalCardSales, totalVietQrSales,
                expected, BigDecimal.ZERO, BigDecimal.ZERO, false, totalOrders, cancelledOrders, session.getStartTime(), LocalDateTime.now());
    }

    /** Called by {@code ShiftAutoCloseScheduler} at 23:59 (BR-88); skips shifts that still have blocking orders. */
    @Transactional
    public void autoClose(UUID sessionId) {
        ShiftSession session = shiftSessionRepository.findById(sessionId).orElse(null);
        if (session == null || session.getStatus() != ShiftStatus.OPEN) {
            return;
        }
        try {
            // BR-88: auto-abandon uncollected READY orders during auto close
            for (Order ready : orderRepository.findByShiftSessionIdAndStatus(session.getId(), OrderStatus.READY)) {
                ready.setStatus(OrderStatus.ABANDONED);
                orderRepository.save(ready);
            }
            reconcileAndClose(session, null, null); // null closing cash → no manual count, no discrepancy alert
            log.info("[scheduler] Auto-closed shift {} (register {})", session.getId(), session.getPosRegisterId());
        } catch (AppException ex) {
            log.warn("[scheduler] Skipped auto-close of shift {} — {}", session.getId(), ex.getMessage());
        }
    }

    public List<ShiftSession> openShifts() {
        return shiftSessionRepository.findByStatus(ShiftStatus.OPEN);
    }

    private ZReportResponse reconcileAndClose(ShiftSession session, BigDecimal closingCash, String notes) {
        // BR-03: cannot close over orders still in progress
        if (orderRepository.existsByShiftSessionIdAndStatusIn(session.getId(), BLOCKING)) {
            throw AppException.of("err.054"); // BR-03
        }

        BigDecimal opening = nz(session.getStartingCash());
        BigDecimal totalCashSales = nz(orderRepository.sumSales(
                session.getId(), PaymentMethod.CASH, PaymentStatus.PAID));
        BigDecimal totalCardSales = nz(orderRepository.sumSales(
                session.getId(), PaymentMethod.CARD, PaymentStatus.PAID));
        BigDecimal totalVietQrSales = nz(orderRepository.sumSales(
                session.getId(), PaymentMethod.VIETQR, PaymentStatus.PAID));

        long totalOrders = orderRepository.countByShiftSessionId(session.getId());
        long cancelledOrders = orderRepository.countByShiftSessionIdAndStatus(session.getId(), OrderStatus.CANCELLED);

        // BR-09: cash refunds authorized against this shift came out of the drawer
        BigDecimal refunds = nz(orderRefundRepository.sumByShiftAndType(session.getId(), RefundType.REFUND));
        BigDecimal expected = opening.add(totalCashSales).subtract(refunds);
        BigDecimal counted = closingCash == null ? expected : closingCash;
        BigDecimal discrepancy = counted.subtract(expected);
        boolean flagged = closingCash != null && discrepancy.abs().compareTo(DISCREPANCY_THRESHOLD) > 0;

        if (flagged) {
            alertStoreManager(session, discrepancy); // BR-04
        }

        session.setEndingCash(closingCash);
        session.setDiscrepancyNotes(notes);
        session.setStatus(ShiftStatus.CLOSED);
        session.setEndTime(LocalDateTime.now());
        shiftSessionRepository.save(session);

        return new ZReportResponse(session.getId(), session.getPosRegisterId(), opening, totalCashSales,
                totalCardSales, totalVietQrSales,
                expected, closingCash, discrepancy, flagged, totalOrders, cancelledOrders, session.getStartTime(), session.getEndTime());
    }

    private void alertStoreManager(ShiftSession session, BigDecimal discrepancy) {
        String body = "Ca " + session.getId() + " (register " + session.getPosRegisterId()
                + ") lệch quỹ " + discrepancy.toPlainString() + " VND.\n"
                + "Ghi chú: " + (session.getDiscrepancyNotes() != null ? session.getDiscrepancyNotes() : "Không có");
        userRepository.findByStoreId(session.getStore().getId()).stream()
                .filter(u -> u.getRole() == Role.STORE_MANAGER)
                .filter(u -> Boolean.TRUE.equals(u.getIsActive()))
                .filter(u -> u.getEmail() != null && !u.getEmail().isBlank())
                .forEach(sm -> emailService.send(sm.getEmail(),
                        "[BR-04] Cảnh báo lệch quỹ ca — " + session.getStore().getName(), body));
        log.warn("[BR-04] Shift {} discrepancy {} flagged", session.getId(), discrepancy);
    }

    private ShiftResponse toResponse(ShiftSession s) {
        return new ShiftResponse(
                s.getId(),
                s.getStore() != null ? s.getStore().getId() : null,
                s.getUser() != null ? s.getUser().getId() : null,
                s.getPosRegisterId(),
                s.getStartingCash(),
                s.getStatus(),
                s.getStartTime());
    }

    private User currentUser(UUID actorId) {
        User user = userRepository.findById(actorId)
                .orElseThrow(() -> AppException.of("err.055"));
        if (user.getStore() == null) {
            throw AppException.of("err.056");
        }
        return user;
    }

    private static BigDecimal nz(BigDecimal v) {
        return v == null ? BigDecimal.ZERO : v;
    }
}
