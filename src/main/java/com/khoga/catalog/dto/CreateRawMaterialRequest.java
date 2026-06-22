package com.khoga.catalog.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.PositiveOrZero;

import java.math.BigDecimal;

public record CreateRawMaterialRequest(
        @NotBlank(message = "Mã nguyên liệu không được để trống") String code,
        @NotBlank(message = "Tên nguyên liệu không được để trống") String name,
        @NotBlank(message = "Đơn vị không được để trống") String unit,
        @PositiveOrZero BigDecimal suggestedMinThreshold,
        @PositiveOrZero BigDecimal standardCost,
        String category) {
}
