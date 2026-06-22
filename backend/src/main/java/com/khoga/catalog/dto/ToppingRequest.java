package com.khoga.catalog.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;

import java.math.BigDecimal;
import java.util.List;

/** UC-71: a topping/option. Price may be 0 (BR-29); recipe is optional (BR-65). */
public record ToppingRequest(
        @NotBlank(message = "Tên topping không được để trống") String name,
        @NotNull @PositiveOrZero(message = "Giá không được âm") BigDecimal price,
        @Valid List<RecipeLineRequest> recipe) {
}
