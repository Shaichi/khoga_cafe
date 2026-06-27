package com.khoga.inventory.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;

import java.math.BigDecimal;
import java.util.UUID;

/** One physically-counted line in a UC-34 stock audit. {@code note} is mandatory when it differs (BR-32). */
public record StockAuditLine(
        @NotNull UUID stockItemId,
        @NotNull @PositiveOrZero BigDecimal actualQuantity,
        String note) {
}
