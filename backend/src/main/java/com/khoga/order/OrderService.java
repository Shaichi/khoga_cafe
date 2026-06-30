package com.khoga.order;

import com.khoga.audit.AuditLogService;
import com.khoga.common.exception.AppException;
import com.khoga.common.exception.ResourceNotFoundException;
import com.khoga.common.model.Customer;
import com.khoga.common.model.Order;
import com.khoga.common.model.OrderCancellation;
import com.khoga.common.model.OrderItem;
import com.khoga.common.model.OrderItemTopping;
import com.khoga.common.model.OrderRefund;
import com.khoga.common.model.ShiftSession;
import com.khoga.common.model.Store;
import com.khoga.common.model.User;
import com.khoga.common.model.Voucher;
import com.khoga.common.model.enums.ActionType;
import com.khoga.common.model.enums.OrderStatus;
import com.khoga.common.model.enums.PaymentMethod;
import com.khoga.common.model.enums.PaymentStatus;
import com.khoga.common.model.enums.RefundType;
import com.khoga.common.model.enums.Role;
import com.khoga.common.model.enums.ShiftStatus;
import com.khoga.common.repository.CustomerRepository;
import com.khoga.common.repository.OrderCancellationRepository;
import com.khoga.common.repository.OrderItemRepository;
import com.khoga.common.repository.OrderItemToppingRepository;
import com.khoga.common.repository.OrderRefundRepository;
import com.khoga.common.repository.OrderRepository;
import com.khoga.common.repository.ShiftSessionRepository;
import com.khoga.common.repository.UserRepository;
import com.khoga.common.repository.VoucherRepository;
import com.khoga.config.SystemConfigService;
import com.khoga.inventory.RecipeDeductionEngine;
import com.khoga.inventory.dto.DeductionResult;
import com.khoga.order.dto.CancelOrderRequest;
import com.khoga.order.dto.OrderDetailResponse;
import com.khoga.order.dto.OrderSummaryResponse;
import com.khoga.order.dto.RefundRequest;
import com.khoga.order.dto.RefundResponse;
import com.khoga.order.dto.StatusUpdateResponse;
import com.khoga.integration.PrinterService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Order lifecycle (UC-54/57/58/73), cancellation (UC-55), SM refund/comp (UC-75) and the scheduled
 * auto-abandon of stale READY orders (BR-88). The 7-state machine is enforced here:
 * PENDING→PREPARING (deducts stock via {@link RecipeDeductionEngine}) →(HOLD)→READY→COMPLETED;
 * PENDING→CANCELLED (cancel only, BR-05) and READY→ABANDONED (system/shift-close) are terminal.
 * Stock is deducted exactly once, at the first PENDING→PREPARING, and is never reversed (BR-07).
 */
@Slf4j
@Service
public class OrderService {

    /** Active states shown in the barista queue (UC-57). */
    private static final List<OrderStatus> QUEUE_STATES =
            List.of(OrderStatus.PENDING, OrderStatus.PREPARING, OrderStatus.HOLD, OrderStatus.READY);

    /** Valid barista transitions (UC-58). Cancel (→CANCELLED) and auto-abandon (→ABANDONED) have own paths. */
    private static final Map<OrderStatus, Set<OrderStatus>> ALLOWED = Map.of(
            OrderStatus.PENDING, Set.of(OrderStatus.PREPARING),
            OrderStatus.PREPARING, Set.of(OrderStatus.HOLD, OrderStatus.READY),
            OrderStatus.HOLD, Set.of(OrderStatus.PREPARING),
            OrderStatus.READY, Set.of(OrderStatus.COMPLETED));

    private static final int DEFAULT_READY_ABANDON_MINUTES = 15;

    private final OrderRepository orderRepository;
    private final OrderItemRepository orderItemRepository;
    private final OrderItemToppingRepository orderItemToppingRepository;
    private final OrderCancellationRepository orderCancellationRepository;
    private final OrderRefundRepository orderRefundRepository;
    private final ShiftSessionRepository shiftSessionRepository;
    private final UserRepository userRepository;
    private final CustomerRepository customerRepository;
    private final VoucherRepository voucherRepository;
    private final RecipeDeductionEngine recipeDeductionEngine;
    private final SystemConfigService config;
    private final PrinterService printerService;
    private final AuditLogService auditLogService;

    public OrderService(OrderRepository orderRepository, OrderItemRepository orderItemRepository,
                        OrderItemToppingRepository orderItemToppingRepository,
                        OrderCancellationRepository orderCancellationRepository,
                        OrderRefundRepository orderRefundRepository,
                        ShiftSessionRepository shiftSessionRepository, UserRepository userRepository,
                        CustomerRepository customerRepository, VoucherRepository voucherRepository,
                        RecipeDeductionEngine recipeDeductionEngine, SystemConfigService config,
                        PrinterService printerService, AuditLogService auditLogService) {
        this.orderRepository = orderRepository;
        this.orderItemRepository = orderItemRepository;
        this.orderItemToppingRepository = orderItemToppingRepository;
        this.orderCancellationRepository = orderCancellationRepository;
        this.orderRefundRepository = orderRefundRepository;
        this.shiftSessionRepository = shiftSessionRepository;
        this.userRepository = userRepository;
        this.customerRepository = customerRepository;
        this.voucherRepository = voucherRepository;
        this.recipeDeductionEngine = recipeDeductionEngine;
        this.config = config;
        this.printerService = printerService;
        this.auditLogService = auditLogService;
    }

    /** UC-57 — live barista queue for the actor's branch, oldest first. */
    @Transactional(readOnly = true)
    public List<OrderSummaryResponse> getQueue(UUID actorId) {
        UUID storeId = currentUser(actorId).getStore().getId();
        return orderRepository.findByStoreIdAndStatusInOrderByCreatedAtAsc(storeId, QUEUE_STATES).stream()
                .map(this::toSummary)
                .toList();
    }

    /** UC-54 — order history for the actor's branch, newest first, optional status filter. */
    @Transactional(readOnly = true)
    public Page<OrderSummaryResponse> getHistory(OrderStatus status, UUID actorId, Pageable pageable) {
        UUID storeId = currentUser(actorId).getStore().getId();
        return orderRepository.findHistory(storeId, status, pageable).map(this::toSummary);
    }

    /** UC-73 — full order detail (header + lines + toppings), branch-scoped. */
    @Transactional(readOnly = true)
    public OrderDetailResponse getDetail(UUID orderId, UUID actorId) {
        Order order = loadForStore(orderId, currentUser(actorId).getStore());
        List<OrderItem> items = orderItemRepository.findByOrderId(order.getId());
        Map<UUID, List<OrderItemTopping>> toppings = items.stream()
                .collect(Collectors.toMap(OrderItem::getId,
                        it -> orderItemToppingRepository.findByOrderItemId(it.getId())));
        return OrderMapper.toDetail(order, items, toppings);
    }

    /** UC-58 — barista state transition; PENDING→PREPARING deducts stock (UC-62), PREPARING→READY prints the label (UC-59). */
    @Transactional
    public StatusUpdateResponse updateStatus(UUID orderId, OrderStatus target, UUID actorId) {
        Order order = loadForStore(orderId, currentUser(actorId).getStore());
        OrderStatus from = order.getStatus();
        if (!ALLOWED.getOrDefault(from, Set.of()).contains(target)) {
            throw new AppException("Không thể chuyển đơn từ " + from + " sang " + target);
        }

        List<String> warnings = List.of();
        if (from == OrderStatus.PENDING && target == OrderStatus.PREPARING) {
            DeductionResult result = recipeDeductionEngine.deductForOrder(order); // UC-62, BR-89 (allows negative)
            if (result.hasShortage()) {
                warnings = result.shortages().stream()
                        .map(s -> s.materialName() + " thiếu " + s.deficit().toPlainString())
                        .toList();
            }
        }

        order.setStatus(target);
        orderRepository.save(order);

        if (target == OrderStatus.READY) {
            printerService.printLabel("Order " + order.getOrderNumber() + " sẵn sàng"); // UC-59
        }
        auditLogService.record(ActionType.UPDATE, "Order", from.name(), target.name(), actorId);
        return new StatusUpdateResponse(order.getId(), order.getOrderNumber(), order.getStatus(), warnings);
    }

    /** UC-55 — cancel a PENDING order (BR-05); logs an immutable cancellation (BR-51) and rolls back any applied voucher/loyalty (BR-08). */
    @Transactional
    public OrderSummaryResponse cancelOrder(UUID orderId, CancelOrderRequest req, UUID actorId) {
        User actor = currentUser(actorId);
        Order order = loadForStore(orderId, actor.getStore());
        if (order.getStatus() != OrderStatus.PENDING) {
            throw AppException.of("err.035");
        }

        OrderCancellation cancellation = new OrderCancellation();
        cancellation.setOrder(order);
        cancellation.setCashier(actor);
        cancellation.setReason(req.reason());
        cancellation.setNotes(req.notes());
        orderCancellationRepository.save(cancellation); // immutable record, BR-51

        if (order.getPaymentStatus() == PaymentStatus.PAID) {
            reversePoints(order);          // BR-08 loyalty rollback
            restoreVoucherUsage(order);    // BR-08 voucher limit restored
            order.setPaymentStatus(PaymentStatus.REFUNDED); // exclude from sales; cash returned
        }
        order.setStatus(OrderStatus.CANCELLED);
        orderRepository.save(order);

        auditLogService.record(ActionType.UPDATE, "OrderCancellation", OrderStatus.PENDING.name(),
                OrderStatus.CANCELLED.name(), actorId);
        return toSummary(order);
    }

    /** UC-75 — SM-authorized refund / comp remake (BR-67/BR-09). SM authorizes via attendance PIN. */
    @Transactional
    public RefundResponse refund(UUID orderId, RefundRequest req, UUID actorId) {
        User actor = currentUser(actorId);
        Store store = actor.getStore();
        Order order = loadForStore(orderId, store);
        User sm = authorizeStoreManager(store.getId(), req.smApprovalPin());

        return switch (req.refundType()) {
            case REFUND -> doRefund(order, req, actor, sm, store);
            case COMP_REMAKE -> doCompRemake(order, req, actor, sm, store);
        };
    }

    private RefundResponse doRefund(Order order, RefundRequest req, User actor, User sm, Store store) {
        if (order.getPaymentStatus() != PaymentStatus.PAID) {
            throw AppException.of("err.036");
        }
        BigDecimal total = nzb(order.getTotal());
        BigDecimal amount = req.amount() == null ? total : req.amount();
        if (amount.signum() <= 0 || amount.compareTo(total) > 0) {
            throw AppException.of("err.037");
        }

        // BR-09: a cash refund comes out of the currently-open drawer; card/VietQR refunds go back via the gateway.
        ShiftSession drawer = order.getPaymentMethod() == PaymentMethod.CASH
                ? shiftSessionRepository.findFirstByStoreIdAndStatus(store.getId(), ShiftStatus.OPEN).orElse(null)
                : null;

        OrderRefund refund = saveRefund(order, sm, actor, drawer, RefundType.REFUND, amount, req);
        reversePoints(order); // reverse accrual / return redeemed points
        order.setPaymentStatus(PaymentStatus.REFUNDED);
        orderRepository.save(order);

        auditLogService.record(ActionType.UPDATE, "OrderRefund", PaymentStatus.PAID.name(),
                PaymentStatus.REFUNDED.name(), actor.getId());
        log.info("[BR-09] Refund {} for order {} amount {} (drawer {})",
                refund.getId(), order.getId(), amount.toPlainString(), drawer != null ? drawer.getId() : "gateway");
        return new RefundResponse(refund.getId(), order.getId(), RefundType.REFUND, amount,
                order.getPaymentStatus(), null);
    }

    private RefundResponse doCompRemake(Order order, RefundRequest req, User actor, User sm, Store store) {
        OrderRefund refund = saveRefund(order, sm, actor, null, RefundType.COMP_REMAKE, BigDecimal.ZERO, req);
        Order remake = cloneAsPending(order, store);
        auditLogService.record(ActionType.CREATE, "OrderRefund", order.getOrderNumber(), remake.getOrderNumber(),
                actor.getId());
        log.info("[BR-67] Comp remake {} → new order {} for original {}",
                refund.getId(), remake.getId(), order.getId());
        return new RefundResponse(refund.getId(), order.getId(), RefundType.COMP_REMAKE, BigDecimal.ZERO,
                order.getPaymentStatus(), remake.getId());
    }

    /** BR-88 — READY orders idle beyond READY_ABANDON_TIMEOUT become ABANDONED (no stock reversal). Called by the scheduler. */
    @Transactional
    public int abandonStaleReadyOrders() {
        int minutes = config.getGlobalInt("READY_ABANDON_TIMEOUT", DEFAULT_READY_ABANDON_MINUTES);
        LocalDateTime cutoff = LocalDateTime.now().minusMinutes(minutes);
        List<Order> stale = orderRepository.findByStatusAndUpdatedAtBefore(OrderStatus.READY, cutoff);
        for (Order order : stale) {
            order.setStatus(OrderStatus.ABANDONED);
            orderRepository.save(order);
            log.info("[BR-88] Order {} auto-abandoned after {}min in READY", order.getOrderNumber(), minutes);
        }
        return stale.size();
    }

    private OrderRefund saveRefund(Order order, User sm, User cashier, ShiftSession shift,
                                   RefundType type, BigDecimal amount, RefundRequest req) {
        OrderRefund refund = new OrderRefund();
        refund.setOrder(order);
        refund.setStoreManager(sm);
        refund.setCashier(cashier);
        refund.setShiftSession(shift);
        refund.setRefundType(type);
        refund.setAmount(amount);
        refund.setReason(req.reason());
        refund.setNotes(req.notes());
        return orderRefundRepository.save(refund);
    }

    private Order cloneAsPending(Order src, Store store) {
        ShiftSession openShift = shiftSessionRepository
                .findFirstByStoreIdAndStatus(store.getId(), ShiftStatus.OPEN).orElse(null);
        Order clone = new Order();
        clone.setStore(store);
        clone.setShiftSession(openShift);
        clone.setCustomer(src.getCustomer());
        clone.setVoucher(null);
        clone.setOrderType(src.getOrderType());
        clone.setOrderNumber("OD-" + System.currentTimeMillis());
        clone.setSubtotal(nzb(src.getSubtotal()));
        clone.setDiscount(nzb(src.getSubtotal())); // 100% comped
        clone.setTaxAmount(BigDecimal.ZERO);
        clone.setTotal(BigDecimal.ZERO);
        clone.setStatus(OrderStatus.PENDING);
        clone.setPaymentMethod(src.getPaymentMethod());
        clone.setPaymentStatus(PaymentStatus.PAID); // nothing due on a comp
        clone.setPointsRedeemed(0);
        clone.setPointsEarned(0);
        Order saved = orderRepository.save(clone);

        for (OrderItem item : orderItemRepository.findByOrderId(src.getId())) {
            OrderItem ni = new OrderItem();
            ni.setOrder(saved);
            ni.setMenuItem(item.getMenuItem());
            ni.setQuantity(item.getQuantity());
            ni.setUnitPrice(item.getUnitPrice());
            OrderItem savedItem = orderItemRepository.save(ni);
            for (OrderItemTopping topping : orderItemToppingRepository.findByOrderItemId(item.getId())) {
                OrderItemTopping nt = new OrderItemTopping();
                nt.setOrderItem(savedItem);
                nt.setTopping(topping.getTopping());
                nt.setQuantity(topping.getQuantity());
                nt.setUnitPrice(topping.getUnitPrice());
                orderItemToppingRepository.save(nt);
            }
        }
        return saved;
    }

    private void reversePoints(Order order) {
        Customer customer = order.getCustomer();
        if (customer == null) {
            return;
        }
        int balance = nz(customer.getPoints());
        balance += nz(order.getPointsRedeemed()); // return points the customer had spent
        balance -= nz(order.getPointsEarned());   // claw back the accrual
        customer.setPoints(Math.max(balance, 0));
        customerRepository.save(customer);
    }

    private void restoreVoucherUsage(Order order) {
        Voucher voucher = order.getVoucher();
        if (voucher == null) {
            return;
        }
        voucher.setTotalUsageCount(Math.max(nz(voucher.getTotalUsageCount()) - 1, 0));
        voucherRepository.save(voucher);
    }

    private User authorizeStoreManager(UUID storeId, String pin) {
        if (!StringUtils.hasText(pin)) {
            throw AppException.of("err.038");
        }
        return userRepository.findByStoreId(storeId).stream()
                .filter(u -> u.getRole() == Role.STORE_MANAGER)
                .filter(u -> Boolean.TRUE.equals(u.getIsActive()))
                .filter(u -> pin.equals(u.getAttendancePin()))
                .findFirst()
                .orElseThrow(() -> AppException.of("err.039"));
    }

    private OrderSummaryResponse toSummary(Order order) {
        return OrderMapper.toSummary(order, orderItemRepository.countByOrderId(order.getId()));
    }

    private Order loadForStore(UUID orderId, Store store) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đơn"));
        if (order.getStore() == null || !order.getStore().getId().equals(store.getId())) {
            throw AppException.of("err.040"); // BR-59 scope
        }
        return order;
    }

    private User currentUser(UUID actorId) {
        User user = userRepository.findById(actorId)
                .orElseThrow(() -> AppException.of("err.041"));
        if (user.getStore() == null) {
            throw AppException.of("err.042");
        }
        return user;
    }

    private static int nz(Integer v) {
        return v == null ? 0 : v;
    }

    private static BigDecimal nzb(BigDecimal v) {
        return v == null ? BigDecimal.ZERO : v;
    }
}
