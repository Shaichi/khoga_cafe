package com.khoga.catalog.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;

import java.math.BigDecimal;

/**
 * UC-18 size variant (S/M/L). Each variant becomes a child {@code MenuItem} row pointing at the base
 * item via {@code parentItemId}, carrying its own size name, SKU and selling price.
 */
public record MenuItemVariantRequest(
        @NotBlank(message = "Tên size không được để trống") String sizeName,
        String sku,
        @NotNull @PositiveOrZero(message = "Giá không được âm") BigDecimal price) {
}
