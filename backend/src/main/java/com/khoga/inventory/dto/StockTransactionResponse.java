package com.khoga.inventory.dto;

import com.khoga.common.model.enums.TransactionType;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/** UC-61 ledger row. */
public record StockTransactionResponse(
        UUID id,
        UUID stockItemId,
        String materialName,
        TransactionType transactionType,
        BigDecimal quantity,
        BigDecimal quantityBefore,
        BigDecimal quantityAfter,
        String reason,
        String managerName,
        LocalDateTime createdAt) {
}
