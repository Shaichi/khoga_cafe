package com.khoga.report.dto;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * UC-76 per menu item over the reporting period: units sold, sales revenue, standard-cost COGS
 * (soldQuantity × unit cost, BR-66) and the resulting gross margin. Unlike a catalog unit-margin,
 * this reflects goods actually sold in the window.
 */
public record ItemMarginRow(
        UUID menuItemId,
        String name,
        long soldQuantity,
        BigDecimal revenue,
        BigDecimal cogs,
        BigDecimal margin,
        BigDecimal marginPercent) {
}
