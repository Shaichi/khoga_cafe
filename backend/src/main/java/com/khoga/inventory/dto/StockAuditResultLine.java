package com.khoga.inventory.dto;

import java.math.BigDecimal;
import java.util.UUID;

/** Per-item discrepancy report returned after a UC-34 audit. */
public record StockAuditResultLine(
        UUID stockItemId,
        String name,
        BigDecimal systemQuantity,
        BigDecimal actualQuantity,
        BigDecimal adjustment) {
}
