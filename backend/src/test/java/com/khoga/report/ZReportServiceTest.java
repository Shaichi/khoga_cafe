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
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

/** UC-81: per-day branch aggregation — gross/voucher/point/net/VAT, tender, counters, provisional banner. */
@ExtendWith(MockitoExtension.class)
class ZReportServiceTest {

    @Mock private OrderRepository orderRepository;
    @Mock private OrderRefundRepository orderRefundRepository;
    @Mock private OrderCancellationRepository orderCancellationRepository;
    @Mock private ShiftSessionRepository shiftSessionRepository;
    @Mock private SystemConfigService config;
    @Mock private ReportScopeResolver scope;
    @InjectMocks private ZReportService service;

    private final UUID actor = UUID.randomUUID();
    private final UUID storeA = UUID.randomUUID();
    private final LocalDate day = LocalDate.of(2026, 5, 24);

    private void stubTotals() {
        when(orderRepository.orderTotals(eq(storeA), any(), any())).thenReturn(new OrderTotalsAccum(
                new BigDecimal("58200000"), new BigDecimal("2540000"),
                new BigDecimal("5060000"), new BigDecimal("55660000"), 6400L)); // 6400 pts × 100 = 640,000
        when(config.getGlobalDecimal(eq("LOYALTY_REDEMPTION_VALUE_PER_POINT"), any())).thenReturn(new BigDecimal("100"));
        when(orderRepository.sumStoreSalesByMethod(eq(storeA), eq(PaymentMethod.CASH), any(), any()))
                .thenReturn(new BigDecimal("21400000"));
        when(orderRepository.sumStoreSalesByMethod(eq(storeA), eq(PaymentMethod.CARD), any(), any()))
                .thenReturn(new BigDecimal("15800000"));
        when(orderRepository.sumStoreSalesByMethod(eq(storeA), eq(PaymentMethod.VIETQR), any(), any()))
                .thenReturn(new BigDecimal("19820000"));
        when(orderRefundRepository.sumByStoreAndRange(eq(storeA), eq(RefundType.REFUND), any(), any()))
                .thenReturn(new BigDecimal("1360000"));
        lenient().when(orderRefundRepository.countByStoreAndRange(eq(storeA), eq(RefundType.REFUND), any(), any()))
                .thenReturn(6L);
        lenient().when(orderCancellationRepository.countByStoreAndRange(eq(storeA), any(), any())).thenReturn(11L);
        lenient().when(orderRepository.countStoreCompleted(eq(storeA), any(), any())).thenReturn(412L);
    }

    @Test
    void zReport_splitsVoucherVsPointAndIsFinalWhenAllClosed() {
        when(scope.resolveBranch(actor, storeA)).thenReturn(storeA);
        stubTotals();
        ShiftSession closed = new ShiftSession();
        closed.setStatus(ShiftStatus.CLOSED);
        when(shiftSessionRepository.findByStoreIdAndStartTimeBetween(eq(storeA), any(), any()))
                .thenReturn(List.of(closed, closed, closed));

        DailyZReport r = service.dailyZReport(day, storeA, actor);

        assertEquals(new BigDecimal("58200000"), r.grossSales());
        assertEquals(new BigDecimal("640000"), r.pointDiscount());       // 6400 × 100
        assertEquals(new BigDecimal("1900000"), r.voucherDiscount());    // 2,540,000 − 640,000
        assertEquals(new BigDecimal("55660000"), r.netSales());
        assertEquals(new BigDecimal("57020000"), r.tender().total());
        assertEquals(3, r.shiftsInDay());
        assertFalse(r.provisional());
    }

    @Test
    void zReport_isProvisionalWhenAShiftStillOpen() {
        when(scope.resolveBranch(actor, storeA)).thenReturn(storeA);
        stubTotals();
        ShiftSession open = new ShiftSession();
        open.setStatus(ShiftStatus.OPEN);
        when(shiftSessionRepository.findByStoreIdAndStartTimeBetween(eq(storeA), any(), any()))
                .thenReturn(List.of(open));

        DailyZReport r = service.dailyZReport(day, storeA, actor);

        assertTrue(r.provisional());
    }

    @Test
    void zReport_requiresASpecificBranch() {
        when(scope.resolveBranch(actor, null)).thenReturn(null);
        assertThrows(AppException.class, () -> service.dailyZReport(day, null, actor));
    }
}
