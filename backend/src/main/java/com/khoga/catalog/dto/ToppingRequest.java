package com.khoga.catalog.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/**
 * UC-71: a global topping/option. Price may be 0 (BR-29); recipe is optional (BR-65). {@code menuItemIds}
 * links the one topping to additional menu items (beyond the item in the request path) — the topping is
 * created once and reused across all of them via join rows, never duplicated (BR-29).
 */
public record ToppingRequest(
        @NotBlank(message = "Tên topping không được để trống") String name,
        @NotNull @PositiveOrZero(message = "Giá không được âm") BigDecimal price,
        @Valid List<RecipeLineRequest> recipe,
        List<UUID> menuItemIds) {
}
