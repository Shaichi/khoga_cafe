package com.khoga.inventory.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.math.BigDecimal;
import java.util.UUID;

/** UC-32 import stock delivery. */
public record ImportStockRequest(
        @NotNull UUID stockItemId,
        @NotNull @Positive BigDecimal quantity,
        String note) {
}
