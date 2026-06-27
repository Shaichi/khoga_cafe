package com.khoga.pos.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.util.List;
import java.util.UUID;

/** One cart line: a menu item, quantity, and the selected global toppings. */
public record CartLineRequest(
        @NotNull UUID menuItemId,
        @NotNull @Positive Integer quantity,
        List<UUID> toppingIds) {
}
