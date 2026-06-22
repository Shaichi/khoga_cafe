package com.khoga.catalog.dto;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public record ToppingResponse(UUID id, String name, BigDecimal price, boolean active, List<RecipeLineResponse> recipe) {
}
