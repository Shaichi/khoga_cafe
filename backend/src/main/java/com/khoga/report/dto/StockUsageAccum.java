package com.khoga.report.dto;

import com.khoga.common.model.enums.TransactionType;

import java.math.BigDecimal;
import java.util.UUID;

/** Internal projection: total stock movement per raw material + transaction type (UC-76 shrinkage). */
public record StockUsageAccum(
        UUID rawMaterialId,
        String name,
        String unit,
        BigDecimal standardCost,
        TransactionType type,
        BigDecimal totalQuantity) {
}
