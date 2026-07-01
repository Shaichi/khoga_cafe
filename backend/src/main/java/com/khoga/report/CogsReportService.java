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
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * UC-76 COGS / margin & ingredient-shrinkage report (BR-66). Revenue, COGS and margin are computed
 * over goods actually sold — COMPLETED order items in the [from, to] window — with COGS =
 * soldQuantity × standard unit cost ({@link CogsCalculator}); {@code items} is the per-menu-item
 * breakdown. Shrinkage folds branch stock movements into theoretical (recipe deductions + phantom
 * usage) vs audited (physical-count adjustments) consumption, valued at standard cost.
 */
@Service
public class CogsReportService {

    /** Flag a material when its loss exceeds this fraction of theoretical consumption. */
    private static final BigDecimal FLAG_RATIO = new BigDecimal("0.05");

    private final OrderItemRepository orderItemRepository;
    private final StockTransactionRepository stockTransactionRepository;
    private final CogsCalculator cogsCalculator;
    private final ReportScopeResolver scope;

    public CogsReportService(OrderItemRepository orderItemRepository,
                             StockTransactionRepository stockTransactionRepository,
                             CogsCalculator cogsCalculator,
                             ReportScopeResolver scope) {
        this.orderItemRepository = orderItemRepository;
        this.stockTransactionRepository = stockTransactionRepository;
        this.cogsCalculator = cogsCalculator;
        this.scope = scope;
    }

    public CogsReport cogsReport(LocalDate from, LocalDate to, UUID branchFilter, UUID actorId) {
        UUID branch = scope.resolveBranch(actorId, branchFilter);
        LocalDateTime fromDt = from.atStartOfDay();
        LocalDateTime toDt = to.plusDays(1).atStartOfDay();

        List<ItemMarginRow> items = new ArrayList<>();
        BigDecimal totalRevenue = BigDecimal.ZERO;
        BigDecimal totalCogs = BigDecimal.ZERO;
        for (SoldItemAggregate a : orderItemRepository.soldAggregateByMenuItem(branch, fromDt, toDt)) {
            BigDecimal revenue = nz(a.revenue());
            BigDecimal cogs = cogsCalculator.menuItemUnitCost(a.menuItemId())
                    .multiply(BigDecimal.valueOf(a.quantity()));
            BigDecimal margin = revenue.subtract(cogs);
            items.add(new ItemMarginRow(a.menuItemId(), a.name(), a.quantity(), revenue, cogs,
                    margin, percent(margin, revenue)));
            totalRevenue = totalRevenue.add(revenue);
            totalCogs = totalCogs.add(cogs);
        }

        BigDecimal totalMargin = totalRevenue.subtract(totalCogs);
        List<ShrinkageRow> shrinkage = shrinkage(branch, fromDt, toDt);
        return new CogsReport(from, to, branch, totalRevenue, totalCogs,
                percent(totalMargin, totalRevenue), items, shrinkage);
    }

    /** margin as a whole-percent of revenue; 0 when there is no revenue. */
    private static BigDecimal percent(BigDecimal part, BigDecimal whole) {
        return whole.signum() == 0
                ? BigDecimal.ZERO
                : part.multiply(BigDecimal.valueOf(100)).divide(whole, 0, RoundingMode.HALF_UP);
    }

    private List<ShrinkageRow> shrinkage(UUID branch, LocalDateTime fromDt, LocalDateTime toDt) {
        // Fold the per-material/per-type accumulators into theoretical vs adjustment.
        Map<UUID, ShrinkageAccum> byMaterial = new LinkedHashMap<>();
        for (StockUsageAccum a : stockTransactionRepository.usageByMaterialAndType(branch, fromDt, toDt)) {
            ShrinkageAccum acc = byMaterial.computeIfAbsent(a.rawMaterialId(),
                    k -> new ShrinkageAccum(a.name(), a.unit(), nz(a.standardCost())));
            BigDecimal qty = nz(a.totalQuantity());
            if (a.type() == TransactionType.RECIPE_DEDUCTION) {
                acc.theoretical = acc.theoretical.add(qty.abs()); // deduction is stored negative
            } else if (a.type() == TransactionType.PHANTOM_USAGE) {
                acc.theoretical = acc.theoretical.add(qty.abs()); // shortfall still theoretically consumed
            } else { // AUDIT_ADJUSTMENT — signed (negative = counted less = extra loss)
                acc.adjustment = acc.adjustment.add(qty);
            }
        }

        List<ShrinkageRow> rows = new ArrayList<>();
        for (Map.Entry<UUID, ShrinkageAccum> e : byMaterial.entrySet()) {
            ShrinkageAccum acc = e.getValue();
            BigDecimal theoretical = acc.theoretical;
            BigDecimal actualUsage = theoretical.subtract(acc.adjustment); // adjust negative → usage up
            BigDecimal variance = theoretical.subtract(actualUsage);       // == adjustment (negative = loss)
            BigDecimal lossValue = variance.negate().multiply(acc.standardCost); // positive = monetary loss
            boolean flagged = theoretical.signum() > 0 && lossValue.signum() > 0
                    && variance.abs().divide(theoretical, 4, RoundingMode.HALF_UP).compareTo(FLAG_RATIO) > 0;
            rows.add(new ShrinkageRow(e.getKey(), acc.name, acc.unit, theoretical, actualUsage,
                    variance, lossValue, flagged));
        }
        return rows;
    }

    private static BigDecimal nz(BigDecimal v) {
        return v == null ? BigDecimal.ZERO : v;
    }

    /** Mutable per-material accumulator while folding stock movements. */
    private static final class ShrinkageAccum {
        private final String name;
        private final String unit;
        private final BigDecimal standardCost;
        private BigDecimal theoretical = BigDecimal.ZERO;
        private BigDecimal adjustment = BigDecimal.ZERO;

        ShrinkageAccum(String name, String unit, BigDecimal standardCost) {
            this.name = name;
            this.unit = unit;
            this.standardCost = standardCost;
        }
    }
}
