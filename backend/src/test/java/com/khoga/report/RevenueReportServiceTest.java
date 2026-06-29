package com.khoga.report;

import com.khoga.common.model.ShiftSession;
import com.khoga.common.model.Store;
import com.khoga.common.model.enums.OrderStatus;
import com.khoga.common.model.enums.PaymentMethod;
import com.khoga.common.model.enums.PaymentStatus;
import com.khoga.common.model.enums.RefundType;
import com.khoga.common.model.enums.ShiftStatus;
import com.khoga.common.repository.OrderItemRepository;
import com.khoga.common.repository.OrderRefundRepository;
import com.khoga.common.repository.OrderRepository;
import com.khoga.common.repository.ShiftSessionRepository;
import com.khoga.report.dto.BestSellerRow;
import com.khoga.report.dto.BranchRevenueRow;
import com.khoga.report.dto.HqConsolidatedReport;
import com.khoga.report.dto.StoreRevenueReport;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.when;

/** P3 UC-28/40 revenue reporting: chain totals/avg/cancellation rate, branch tender + discrepancy. */
@ExtendWith(MockitoExtension.class)
class RevenueReportServiceTest {

    @Mock private OrderRepository orderRepository;
    @Mock private OrderItemRepository orderItemRepository;
    @Mock private ShiftSessionRepository shiftSessionRepository;
    @Mock private OrderRefundRepository orderRefundRepository;
    @Mock private ReportScopeResolver scope;
    @InjectMocks private RevenueReportService service;

    private final UUID actor = UUID.randomUUID();
    private final UUID storeA = UUID.randomUUID();
    private final UUID storeB = UUID.randomUUID();
    private final LocalDate from = LocalDate.of(2026, 5, 1);
    private final LocalDate to = LocalDate.of(2026, 5, 31);

    @Test
    void hqConsolidated_sumsBranchesAndComputesAvgAndCancellationRate() {
        when(scope.resolveBranch(actor, null)).thenReturn(null);
        when(orderRepository.revenueByBranch(any(), any())).thenReturn(List.of(
                new BranchRevenueRow(storeA, "District 1", new BigDecimal("250000000"), 6800),
                new BranchRevenueRow(storeB, "Thu Duc", new BigDecimal("200000000"), 5700)));
        when(orderRepository.countByStatusInRange(eq(OrderStatus.CANCELLED), isNull(), any(), any())).thenReturn(125L);
        when(orderRepository.countCreatedInRange(isNull(), any(), any())).thenReturn(12500L);
        when(orderItemRepository.soldByMenuItem(isNull(), any(), any(), any()))
                .thenReturn(List.of(new BestSellerRow(UUID.randomUUID(), "Peach Tea", 3400)));

        HqConsolidatedReport r = service.hqConsolidated(from, to, null, actor);

        assertEquals(new BigDecimal("450000000"), r.totalRevenue());
        assertEquals(12500L, r.totalOrders());
        assertEquals(new BigDecimal("36000"), r.avgTransactionValue());      // 450M / 12500
        assertEquals(new BigDecimal("1.00"), r.cancellationRate());          // 125/12500 = 1.00%
        assertEquals(2, r.branches().size());
        assertEquals("Peach Tea", r.bestSellers().get(0).name());
    }

    @Test
    void hqConsolidated_branchFilterNarrowsToOneBranch() {
        when(scope.resolveBranch(actor, storeA)).thenReturn(storeA);
        when(orderRepository.revenueByBranch(any(), any())).thenReturn(List.of(
                new BranchRevenueRow(storeA, "District 1", new BigDecimal("250000000"), 6800),
                new BranchRevenueRow(storeB, "Thu Duc", new BigDecimal("200000000"), 5700)));
        when(orderRepository.countByStatusInRange(eq(OrderStatus.CANCELLED), eq(storeA), any(), any())).thenReturn(0L);
        when(orderRepository.countCreatedInRange(eq(storeA), any(), any())).thenReturn(6800L);
        when(orderItemRepository.soldByMenuItem(eq(storeA), any(), any(), any())).thenReturn(List.of());

        HqConsolidatedReport r = service.hqConsolidated(from, to, storeA, actor);

        assertEquals(1, r.branches().size());
        assertEquals(new BigDecimal("250000000"), r.totalRevenue());
        assertEquals(6800L, r.totalOrders());
    }

    @Test
    void storeRevenue_computesTenderAndDrawerDiscrepancy() {
        when(scope.requireOwnBranch(actor)).thenReturn(storeA);
        when(orderRepository.sumStoreRevenue(eq(storeA), any(), any())).thenReturn(new BigDecimal("55660000"));
        when(orderRepository.countStoreCompleted(eq(storeA), any(), any())).thenReturn(412L);
        when(orderRepository.sumStoreSalesByMethod(eq(storeA), eq(PaymentMethod.CASH), any(), any()))
                .thenReturn(new BigDecimal("21400000"));
        when(orderRepository.sumStoreSalesByMethod(eq(storeA), eq(PaymentMethod.CARD), any(), any()))
                .thenReturn(new BigDecimal("15800000"));
        when(orderRepository.sumStoreSalesByMethod(eq(storeA), eq(PaymentMethod.VIETQR), any(), any()))
                .thenReturn(new BigDecimal("19820000"));

        ShiftSession closed = new ShiftSession();
        closed.setId(UUID.randomUUID());
        Store st = new Store();
        st.setId(storeA);
        closed.setStore(st);
        closed.setStatus(ShiftStatus.CLOSED);
        closed.setStartingCash(new BigDecimal("1000000"));
        closed.setEndingCash(new BigDecimal("1490000")); // expected = 1,000,000 + 500,000 − 10,000 = 1,490,000 → 0 discrepancy
        when(shiftSessionRepository.findByStoreIdAndStartTimeBetween(eq(storeA), any(), any()))
                .thenReturn(List.of(closed));
        when(orderRepository.sumSales(closed.getId(), PaymentMethod.CASH, PaymentStatus.PAID))
                .thenReturn(new BigDecimal("500000"));
        when(orderRefundRepository.sumByShiftAndType(closed.getId(), RefundType.REFUND))
                .thenReturn(new BigDecimal("10000"));

        StoreRevenueReport r = service.storeRevenue(from, to, actor);

        assertEquals(new BigDecimal("55660000"), r.netRevenue());
        assertEquals(412L, r.completedOrders());
        assertEquals(new BigDecimal("57020000"), r.payments().total());
        assertEquals(0, BigDecimal.ZERO.compareTo(r.discrepancyTotal()));
    }
}
