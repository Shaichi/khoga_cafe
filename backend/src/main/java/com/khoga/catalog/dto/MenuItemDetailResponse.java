package com.khoga.catalog.dto;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public record MenuItemDetailResponse(
        UUID id, String name, BigDecimal price, UUID categoryId, String categoryName,
        String abbreviation, String barcode, String description, String imageUrl,
        UUID parentItemId, String sizeName,
        boolean active, boolean deleted,
        List<RecipeLineResponse> recipe, List<ToppingResponse> toppings) {
}
