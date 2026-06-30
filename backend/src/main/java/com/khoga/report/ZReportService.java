package com.khoga.report;

import com.khoga.common.exception.AppException;
import com.khoga.common.model.ShiftSession;
import com.khoga.common.model.enums.PaymentMethod;
import com.khoga.common.model.enums.RefundType;
import com.khoga.common.model.enums.ShiftStatus;
import com.khoga.common.repository.OrderCancellationRepository;
import com.khoga.common.repository.OrderRefundRepository;
import com.khoga.common.repository.OrderRepository;
import com.khoga.common.repository.ShiftSessionRepository;
import com.khoga.config.SystemConfigService;
import com.khoga.report.dto.DailyZReport;
import com.khoga.report.dto.OrderTotalsAccum;
import com.khoga.report.dto.PaymentBreakdown;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * UC-81 daily Z-report (BR-78): aggregates all of a branch's shift sessions for one business day into
 * a single statement — gross/net sales, voucher &amp; point discounts, VAT, refunds, tender breakdown,
 * and counters. Reconciles to the sum of that day's close-shift reports (UC-53).
 */
@Service
public class ZReportService {

    private final OrderRepository orderRepository;
    private final OrderRefundRepository orderRefundRepository;
    private final OrderCancellationRepository orderCancellationRepository;
    private final ShiftSessionRepository shiftSessionRepository;
    private final SystemConfigService config;
    private final ReportScopeResolver scope;

    public ZReportService(OrderRepository orderRepository,
                          OrderRefundRepository orderRefundRepository,
                          OrderCancellationRepository orderCancellationRepository,
                          ShiftSessionRepository shiftSessionRepository,
                          SystemConfigService config,
                          ReportScopeResolver scope) {
        this.orderRepository = orderRepository;
        this.orderRefundRepository = orderRefundRepository;
        this.orderCancellationRepository = orderCancellationRepository;
        this.shiftSessionRepository = shiftSessionRepository;
        this.config = config;
        this.scope = scope;
    }

    public DailyZReport dailyZReport(LocalDate businessDay, UUID branchFilter, UUID actorId) {
        UUID storeId = scope.resolveBranch(actorId, branchFilter);
        if (storeId == null) {
            throw AppException.of("err.060");
        }
        LocalDateTime fromDt = businessDay.atStartOfDay();
        LocalDateTime toDt = businessDay.plusDays(1).atStartOfDay();

        OrderTotalsAccum totals = orderRepository.orderTotals(storeId, fromDt, toDt);
        BigDecimal gross = nz(totals.gross());
        BigDecimal discount = nz(totals.discount());
        BigDecimal valuePerPoint = config.getGlobalDecimal("LOYALTY_REDEMPTION_VALUE_PER_POINT", new BigDecimal("100"));
        BigDecimal pointDiscount = valuePerPoint.multiply(BigDecimal.valueOf(totals.pointsRedeemed()));
        BigDecimal voucherDiscount = discount.subtract(pointDiscount).max(BigDecimal.ZERO);

        PaymentBreakdown tender = new PaymentBreakdown(
                orderRepository.sumStoreSalesByMethod(storeId, PaymentMethod.CASH, fromDt, toDt),
                orderRepository.sumStoreSalesByMethod(storeId, PaymentMethod.CARD, fromDt, toDt),
                orderRepository.sumStoreSalesByMethod(storeId, PaymentMethod.VIETQR, fromDt, toDt));

        BigDecimal refunds = orderRefundRepository.sumByStoreAndRange(storeId, RefundType.REFUND, fromDt, toDt);
        long refundCount = orderRefundRepository.countByStoreAndRange(storeId, RefundType.REFUND, fromDt, toDt);
        long pendingCancellations = orderCancellationRepository.countByStoreAndRange(storeId, fromDt, toDt);
        long ordersCompleted = orderRepository.countStoreCompleted(storeId, fromDt, toDt);

        List<ShiftSession> shifts = shiftSessionRepository.findByStoreIdAndStartTimeBetween(storeId, fromDt, toDt);
        boolean provisional = shifts.stream().anyMatch(s -> s.getStatus() == ShiftStatus.OPEN);

        return new DailyZReport(businessDay, storeId, gross, voucherDiscount, pointDiscount,
                nz(totals.net()), nz(totals.tax()), refunds, tender,
                ordersCompleted, refundCount, pendingCancellations, shifts.size(), provisional);
    }

    private static BigDecimal nz(BigDecimal v) {
        return v == null ? BigDecimal.ZERO : v;
    }
}
