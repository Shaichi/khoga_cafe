package com.khoga.catalog.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.math.BigDecimal;
import java.util.UUID;

/** One recipe line. {@code unit} must equal the raw material's master unit (BR-73). */
public record RecipeLineRequest(
        @NotNull(message = "Nguyên liệu không được để trống") UUID rawMaterialId,
        @NotNull @Positive(message = "Số lượng phải lớn hơn 0") BigDecimal quantity,
        @NotBlank(message = "Đơn vị không được để trống") String unit) {
}
