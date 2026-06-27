package com.khoga.inventory.dto;

import java.math.BigDecimal;
import java.util.UUID;

/** Low-stock alert payload (MSG07). */
public record LowStockAlertDto(
        UUID stockItemId,
        String code,
        String name,
        BigDecimal currentQuantity,
        BigDecimal minAlertThreshold) {
}
