package com.khoga.catalog.dto;

import java.math.BigDecimal;
import java.util.UUID;

public record MenuItemResponse(
        UUID id, String name, BigDecimal price, UUID categoryId, String categoryName,
        String abbreviation, String barcode, UUID parentItemId, String sizeName,
        boolean active, boolean deleted, boolean available) {
}
