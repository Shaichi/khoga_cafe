package com.khoga.report;

import com.khoga.common.model.ShiftSession;
import com.khoga.common.model.enums.PaymentMethod;
import com.khoga.common.model.enums.RefundType;
import com.khoga.common.model.enums.ShiftStatus;
import com.khoga.common.model.enums.OrderStatus;
import com.khoga.common.repository.OrderItemRepository;
import com.khoga.common.repository.OrderRefundRepository;
import com.khoga.common.repository.OrderRepository;
import com.khoga.common.repository.ShiftSessionRepository;
import com.khoga.report.dto.BestSellerRow;
import com.khoga.report.dto.BranchRevenueRow;
import com.khoga.report.dto.HqConsolidatedReport;
import com.khoga.report.dto.PaymentBreakdown;
import com.khoga.report.dto.StoreRevenueReport;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * UC-28/29 (HQ consolidated) and UC-40/41 (store revenue) revenue reporting (read-only). All figures
 * are over COMPLETED orders in the date range; branch scope is enforced by {@link ReportScopeResolver}
 * (BR-44).
 */
@Service
public class RevenueReportService {

    private static final int BEST_SELLER_LIMIT = 5;

    private final OrderRepository orderRepository;
    private final OrderItemRepository orderItemRepository;
    private final ShiftSessionRepository shiftSessionRepository;
    private final OrderRefundRepository orderRefundRepository;
    private final ReportScopeResolver scope;

    public RevenueReportService(OrderRepository orderRepository,
                                OrderItemRepository orderItemRepository,
                                ShiftSessionRepository shiftSessionRepository,
                                OrderRefundRepository orderRefundRepository,
                                ReportScopeResolver scope) {
        this.orderRepository = orderRepository;
        this.orderItemRepository = orderItemRepository;
        this.shiftSessionRepository = shiftSessionRepository;
        this.orderRefundRepository = orderRefundRepository;
        this.scope = scope;
    }

    /** UC-28: chain-wide totals + per-branch comparison + best sellers (HQ role; optional branch filter). */
    public HqConsolidatedReport hqConsolidated(LocalDate from, LocalDate to, UUID branchFilter, UUID actorId) {
        UUID branch = scope.resolveBranch(actorId, branchFilter); // null = all branches
        LocalDateTime fromDt = from.atStartOfDay();
        LocalDateTime toDt = to.plusDays(1).atStartOfDay();

        List<BranchRevenueRow> branches = orderRepository.revenueByBranch(fromDt, toDt).stream()
                .filter(r -> branch == null || branch.equals(r.storeId()))
                .toList();

        BigDecimal totalRevenue = BigDecimal.ZERO;
        long totalOrders = 0;
        for (BranchRevenueRow r : branches) {
            totalRevenue = totalRevenue.add(r.revenue());
            totalOrders += r.orders();
        }
        BigDecimal avg = totalOrders == 0
                ? BigDecimal.ZERO
                : totalRevenue.divide(BigDecimal.valueOf(totalOrders), 0, RoundingMode.HALF_UP);

        long cancelled = orderRepository.countByStatusInRange(OrderStatus.CANCELLED, branch, fromDt, toDt);
        long created = orderRepository.countCreatedInRange(branch, fromDt, toDt);
        BigDecimal cancellationRate = created == 0
                ? BigDecimal.ZERO
                : BigDecimal.valueOf(cancelled).multiply(BigDecimal.valueOf(100))
                        .divide(BigDecimal.valueOf(created), 2, RoundingMode.HALF_UP);

        List<BestSellerRow> bestSellers =
                orderItemRepository.soldByMenuItem(branch, fromDt, toDt, PageRequest.of(0, BEST_SELLER_LIMIT));

        return new HqConsolidatedReport(from, to, totalRevenue, totalOrders, avg,
                cancellationRate, branches, bestSellers);
    }

    /** UC-40: one branch's net revenue, completed orders, drawer discrepancy + tender breakdown. */
    public StoreRevenueReport storeRevenue(LocalDate from, LocalDate to, UUID actorId) {
        UUID storeId = scope.requireOwnBranch(actorId);
        LocalDateTime fromDt = from.atStartOfDay();
        LocalDateTime toDt = to.plusDays(1).atStartOfDay();

        BigDecimal netRevenue = orderRepository.sumStoreRevenue(storeId, fromDt, toDt);
        long completedOrders = orderRepository.countStoreCompleted(storeId, fromDt, toDt);

        PaymentBreakdown payments = new PaymentBreakdown(
                orderRepository.sumStoreSalesByMethod(storeId, PaymentMethod.CASH, fromDt, toDt),
                orderRepository.sumStoreSalesByMethod(storeId, PaymentMethod.CARD, fromDt, toDt),
                orderRepository.sumStoreSalesByMethod(storeId, PaymentMethod.VIETQR, fromDt, toDt));

        BigDecimal discrepancyTotal = discrepancyTotal(storeId, fromDt, toDt);

        return new StoreRevenueReport(from, to, storeId, netRevenue, completedOrders, discrepancyTotal, payments);
    }

    /** Sum of per-shift drawer discrepancies (closing − expected) for closed shifts started in the window. */
    private BigDecimal discrepancyTotal(UUID storeId, LocalDateTime fromDt, LocalDateTime toDt) {
        BigDecimal total = BigDecimal.ZERO;
        for (ShiftSession s : shiftSessionRepository.findByStoreIdAndStartTimeBetween(storeId, fromDt, toDt)) {
            if (s.getStatus() != ShiftStatus.CLOSED || s.getEndingCash() == null) {
                continue;
            }
            BigDecimal cashSales = orderRepository.sumSales(
                    s.getId(), PaymentMethod.CASH, com.khoga.common.model.enums.PaymentStatus.PAID);
            BigDecimal cashRefunds = orderRefundRepository.sumByShiftAndType(s.getId(), RefundType.REFUND);
            BigDecimal opening = s.getStartingCash() == null ? BigDecimal.ZERO : s.getStartingCash();
            BigDecimal expected = opening.add(cashSales).subtract(cashRefunds);
            total = total.add(s.getEndingCash().subtract(expected));
        }
        return total;
    }
}
