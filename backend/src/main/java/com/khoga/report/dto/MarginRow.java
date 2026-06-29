package com.khoga.report.dto;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * UC-76 gross margin for one menu item or topping: selling price vs standard-cost COGS (BR-66).
 * {@code kind} is {@code "ITEM"} or {@code "TOPPING"}.
 */
public record MarginRow(
        UUID itemId,
        String name,
        String kind,
        BigDecimal price,
        BigDecimal cogs,
        BigDecimal margin,
        BigDecimal marginPercent) {
}
