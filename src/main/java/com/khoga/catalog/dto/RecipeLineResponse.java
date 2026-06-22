package com.khoga.catalog.dto;

import java.math.BigDecimal;
import java.util.UUID;

public record RecipeLineResponse(UUID rawMaterialId, String rawMaterialName, BigDecimal quantity, String unit) {
}
