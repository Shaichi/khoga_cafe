package com.khoga.report.dto;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * UC-76 ingredient shrinkage for one raw material: theoretical consumption (recipe deductions +
 * phantom usage) vs actual usage (theoretical adjusted by physical-audit deltas), the variance, and
 * its value at standard cost (positive = monetary loss). {@code flagged} marks abnormal variance.
 */
public record ShrinkageRow(
        UUID rawMaterialId,
        String name,
        String unit,
        BigDecimal theoretical,
        BigDecimal actualUsage,
        BigDecimal variance,
        BigDecimal lossValue,
        boolean flagged) {
}
