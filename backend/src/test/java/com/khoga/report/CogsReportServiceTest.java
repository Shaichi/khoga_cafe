package com.khoga.report;

import com.khoga.common.model.enums.TransactionType;
import com.khoga.common.repository.OrderItemRepository;
import com.khoga.common.repository.StockTransactionRepository;
import com.khoga.inventory.CogsCalculator;
import com.khoga.report.dto.CogsReport;
import com.khoga.report.dto.ItemMarginRow;
import com.khoga.report.dto.ShrinkageRow;
import com.khoga.report.dto.SoldItemAggregate;
import com.khoga.report.dto.StockUsageAccum;
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
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.when;

/** UC-76: period COGS/margin over sold order items (BR-66) + ingredient shrinkage (theoretical vs audited). */
@ExtendWith(MockitoExtension.class)
class CogsReportServiceTest {

    @Mock private OrderItemRepository orderItemRepository;
    @Mock private StockTransactionRepository stockTransactionRepository;
    @Mock private CogsCalculator cogsCalculator;
    @Mock private ReportScopeResolver scope;
    @InjectMocks private CogsReportService service;

    private final UUID actor = UUID.randomUUID();
    private final LocalDate from = LocalDate.of(2026, 5, 1);
    private final LocalDate to = LocalDate.of(2026, 5, 31);

    @Test
    void margin_isRevenueMinusPeriodCogs_overSoldItems() {
        UUID espresso = UUID.randomUUID();
        when(scope.resolveBranch(actor, null)).thenReturn(null);
        when(orderItemRepository.soldAggregateByMenuItem(isNull(), any(), any())).thenReturn(List.of(
                // 10 sold, revenue 300,000 (actual line prices)
                new SoldItemAggregate(espresso, "Espresso", 10L, new BigDecimal("300000"))));
        when(cogsCalculator.menuItemUnitCost(espresso)).thenReturn(new BigDecimal("8500"));
        when(stockTransactionRepository.usageByMaterialAndType(isNull(), any(), any())).thenReturn(List.of());

        CogsReport r = service.cogsReport(from, to, null, actor);

        ItemMarginRow row = r.items().get(0);
        assertEquals(10L, row.soldQuantity());
        assertEquals(0, new BigDecimal("85000").compareTo(row.cogs()));        // 10 × 8500
        assertEquals(0, new BigDecimal("300000").compareTo(row.revenue()));
        assertEquals(0, new BigDecimal("215000").compareTo(row.margin()));
        assertEquals(0, new BigDecimal("72").compareTo(row.marginPercent()));  // 215000/300000 → 72
        // period totals mirror the single sold item
        assertEquals(0, new BigDecimal("300000").compareTo(r.totalRevenue()));
        assertEquals(0, new BigDecimal("85000").compareTo(r.totalCogs()));
        assertEquals(0, new BigDecimal("72").compareTo(r.totalMarginPercent()));
    }

    @Test
    void noSales_yieldZeroTotalsAndEmptyItems() {
        when(scope.resolveBranch(actor, null)).thenReturn(null);
        when(orderItemRepository.soldAggregateByMenuItem(isNull(), any(), any())).thenReturn(List.of());
        when(stockTransactionRepository.usageByMaterialAndType(isNull(), any(), any())).thenReturn(List.of());

        CogsReport r = service.cogsReport(from, to, null, actor);

        assertTrue(r.items().isEmpty());
        assertEquals(0, BigDecimal.ZERO.compareTo(r.totalRevenue()));
        assertEquals(0, BigDecimal.ZERO.compareTo(r.totalCogs()));
        assertEquals(0, BigDecimal.ZERO.compareTo(r.totalMarginPercent()));
    }

    @Test
    void shrinkage_foldsTheoreticalVsAuditAndFlagsAbnormal() {
        when(scope.resolveBranch(actor, null)).thenReturn(null);
        when(orderItemRepository.soldAggregateByMenuItem(isNull(), any(), any())).thenReturn(List.of());

        UUID milk = UUID.randomUUID();
        UUID beans = UUID.randomUUID();
        when(stockTransactionRepository.usageByMaterialAndType(isNull(), any(), any())).thenReturn(List.of(
                // Fresh Milk: theoretical 120 (recipe deductions stored negative), audit −11.5 → loss
                new StockUsageAccum(milk, "Fresh Milk", "L", new BigDecimal("20000"),
                        TransactionType.RECIPE_DEDUCTION, new BigDecimal("-120.0")),
                new StockUsageAccum(milk, "Fresh Milk", "L", new BigDecimal("20000"),
                        TransactionType.AUDIT_ADJUSTMENT, new BigDecimal("-11.5")),
                // Coffee Beans: theoretical 18, audit −0.4 → small, not flagged
                new StockUsageAccum(beans, "Coffee Beans", "kg", new BigDecimal("150000"),
                        TransactionType.RECIPE_DEDUCTION, new BigDecimal("-18.0")),
                new StockUsageAccum(beans, "Coffee Beans", "kg", new BigDecimal("150000"),
                        TransactionType.AUDIT_ADJUSTMENT, new BigDecimal("-0.4"))));

        CogsReport r = service.cogsReport(from, to, null, actor);

        ShrinkageRow milkRow = r.shrinkage().stream().filter(s -> s.rawMaterialId().equals(milk)).findFirst().orElseThrow();
        assertEquals(0, new BigDecimal("120.0").compareTo(milkRow.theoretical()));
        assertEquals(0, new BigDecimal("131.5").compareTo(milkRow.actualUsage()));   // 120 − (−11.5)
        assertEquals(0, new BigDecimal("230000.0").compareTo(milkRow.lossValue())); // 11.5 × 20000
        assertTrue(milkRow.flagged(), "9.6% loss should be flagged");

        ShrinkageRow beansRow = r.shrinkage().stream().filter(s -> s.rawMaterialId().equals(beans)).findFirst().orElseThrow();
        assertFalse(beansRow.flagged(), "2.2% loss is within tolerance");
    }
}
