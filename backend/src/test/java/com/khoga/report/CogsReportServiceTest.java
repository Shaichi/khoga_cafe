package com.khoga.report;

import com.khoga.common.model.MenuItem;
import com.khoga.common.model.OptionTopping;
import com.khoga.common.model.enums.TransactionType;
import com.khoga.common.repository.MenuItemRepository;
import com.khoga.common.repository.OptionToppingRepository;
import com.khoga.common.repository.StockTransactionRepository;
import com.khoga.inventory.CogsCalculator;
import com.khoga.report.dto.CogsReport;
import com.khoga.report.dto.MarginRow;
import com.khoga.report.dto.ShrinkageRow;
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

/** UC-76: per-item standard-cost margin (BR-66) + ingredient shrinkage (theoretical vs audited). */
@ExtendWith(MockitoExtension.class)
class CogsReportServiceTest {

    @Mock private MenuItemRepository menuItemRepository;
    @Mock private OptionToppingRepository optionToppingRepository;
    @Mock private StockTransactionRepository stockTransactionRepository;
    @Mock private CogsCalculator cogsCalculator;
    @Mock private ReportScopeResolver scope;
    @InjectMocks private CogsReportService service;

    private final UUID actor = UUID.randomUUID();
    private final LocalDate from = LocalDate.of(2026, 5, 1);
    private final LocalDate to = LocalDate.of(2026, 5, 31);

    @Test
    void margin_isPriceMinusStandardCogs() {
        when(scope.resolveBranch(actor, null)).thenReturn(null);
        MenuItem espresso = new MenuItem();
        espresso.setId(UUID.randomUUID());
        espresso.setName("Espresso");
        espresso.setPrice(new BigDecimal("30000"));
        when(menuItemRepository.findByIsDeletedFalseOrderByName()).thenReturn(List.of(espresso));
        when(optionToppingRepository.findByIsActiveTrueOrderByName()).thenReturn(List.of());
        when(cogsCalculator.menuItemUnitCost(espresso.getId())).thenReturn(new BigDecimal("8500"));
        when(stockTransactionRepository.usageByMaterialAndType(isNull(), any(), any())).thenReturn(List.of());

        CogsReport r = service.cogsReport(from, to, null, actor);

        MarginRow row = r.margins().get(0);
        assertEquals(new BigDecimal("21500"), row.margin());
        assertEquals(new BigDecimal("72"), row.marginPercent()); // 21500/30000 = 71.6% → 72
    }

    @Test
    void shrinkage_foldsTheoreticalVsAuditAndFlagsAbnormal() {
        when(scope.resolveBranch(actor, null)).thenReturn(null);
        when(menuItemRepository.findByIsDeletedFalseOrderByName()).thenReturn(List.of());
        when(optionToppingRepository.findByIsActiveTrueOrderByName()).thenReturn(List.of());

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
