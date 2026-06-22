package com.khoga.customer.dto;

import com.khoga.common.model.enums.OrderStatus;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/** Thin projection for a customer's purchase history (UC-27). */
public record CustomerOrderEntry(UUID orderId, String orderNumber, BigDecimal total,
                                 OrderStatus status, LocalDateTime createdAt) {
}
