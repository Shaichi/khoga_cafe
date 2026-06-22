package com.khoga.catalog.dto;

import java.math.BigDecimal;
import java.util.UUID;

public record RawMaterialResponse(
        UUID id, String code, String name, String unit,
        BigDecimal suggestedMinThreshold, BigDecimal standardCost, String category, boolean active) {
}
