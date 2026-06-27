package com.khoga.inventory.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;

import java.math.BigDecimal;
import java.util.UUID;

/** Provision a raw material into the current branch's stock (quantity starts at 0). */
public record CreateStockItemRequest(
        @NotNull UUID rawMaterialId,
        @NotNull @PositiveOrZero BigDecimal minAlertThreshold) {
}
