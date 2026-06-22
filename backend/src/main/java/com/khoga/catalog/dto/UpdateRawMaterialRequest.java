package com.khoga.catalog.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.PositiveOrZero;

import java.math.BigDecimal;

/** {@code code} is intentionally absent — it is immutable (BR-63). {@code unit} is locked once the
 *  material has stock/recipe usage (BR-64). */
public record UpdateRawMaterialRequest(
        @NotBlank(message = "Tên nguyên liệu không được để trống") String name,
        @NotBlank(message = "Đơn vị không được để trống") String unit,
        @PositiveOrZero BigDecimal suggestedMinThreshold,
        @PositiveOrZero BigDecimal standardCost,
        String category,
        Boolean active) {
}
