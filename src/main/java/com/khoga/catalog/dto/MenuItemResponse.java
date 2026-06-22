package com.khoga.catalog.dto;

import java.math.BigDecimal;
import java.util.UUID;

public record MenuItemResponse(
        UUID id, String name, BigDecimal price, UUID categoryId, String categoryName,
        String abbreviation, String barcode, boolean active, boolean deleted) {
}
