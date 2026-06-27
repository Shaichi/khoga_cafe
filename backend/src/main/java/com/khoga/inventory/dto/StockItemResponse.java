package com.khoga.inventory.dto;

import java.math.BigDecimal;
import java.util.UUID;

/** UC-31 stock dashboard row. {@code lowStock} = currentQuantity ≤ minAlertThreshold (or negative, BR-89). */
public record StockItemResponse(
        UUID id,
        UUID rawMaterialId,
        String code,
        String name,
        String unit,
        BigDecimal currentQuantity,
        BigDecimal minAlertThreshold,
        BigDecimal standardCost,
        boolean lowStock) {
}
