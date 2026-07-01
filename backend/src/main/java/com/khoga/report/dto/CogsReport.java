package com.khoga.report.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * UC-76 COGS / margin & ingredient-shrinkage report (BR-66). Revenue, COGS and margin are aggregated
 * over goods actually sold (COMPLETED orders) in the [from, to] window; {@code items} breaks that down
 * per menu item. {@code shrinkage} compares theoretical vs audited ingredient consumption.
 * {@code storeId} null = chain-wide.
 */
public record CogsReport(
        LocalDate from,
        LocalDate to,
        UUID storeId,
        BigDecimal totalRevenue,
        BigDecimal totalCogs,
        BigDecimal totalMarginPercent,
        List<ItemMarginRow> items,
        List<ShrinkageRow> shrinkage) {
}
