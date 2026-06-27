package com.khoga.order.dto;

import com.khoga.common.model.enums.OrderStatus;

import java.util.List;
import java.util.UUID;

/**
 * Result of a status transition (UC-58). On PENDING→PREPARING the recipe deduction runs; any
 * ingredient that went negative (phantom usage, BR-89) is surfaced in {@code stockWarnings} so the
 * barista is told to restock — the transition still succeeds (stock may go negative, BR-89).
 */
public record StatusUpdateResponse(
        UUID id,
        String orderNumber,
        OrderStatus status,
        List<String> stockWarnings) {
}
