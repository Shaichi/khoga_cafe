package com.khoga.catalog.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public record CreateMenuItemRequest(
        @NotBlank(message = "Tên món không được để trống") String name,
        @NotNull @PositiveOrZero(message = "Giá không được âm") BigDecimal price,
        String description,
        UUID categoryId,
        String barcode,
        String imageUrl,
        @Valid List<RecipeLineRequest> recipe,
        @Valid List<MenuItemVariantRequest> variants) {
}
