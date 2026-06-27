package com.khoga.inventory.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.math.BigDecimal;
import java.util.UUID;

/** UC-33 export/withdraw stock (e.g. wastage/damage) — reason mandatory. */
public record ExportStockRequest(
        @NotNull UUID stockItemId,
        @NotNull @Positive BigDecimal quantity,
        @NotBlank String reason) {
}
