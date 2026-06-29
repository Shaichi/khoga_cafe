package com.khoga.report.dto;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * UC-79 labour productivity for one branch (or the chain total): worked hours vs net sales, plus the
 * two ratios — hours per 1,000,000 VND and VND per labour hour (BR-76). Non-monetary on the labour
 * side (hours only, no wages). {@code storeId} null marks the chain-total row.
 */
public record LabourRow(
        UUID storeId,
        String storeName,
        BigDecimal labourHours,
        BigDecimal netSales,
        BigDecimal hoursPerMillion,
        BigDecimal vndPerHour) {
}
