package com.khoga.report.dto;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Per-menu-item sales aggregate over the reporting period (COMPLETED orders): units sold and gross
 * sales revenue (Σ quantity × unitPrice). The COGS basis for UC-76 (BR-66).
 */
public record SoldItemAggregate(UUID menuItemId, String name, long quantity, BigDecimal revenue) {
}
