package com.khoga.order.dto;

import com.khoga.common.model.enums.OrderStatus;
import com.khoga.common.model.enums.OrderType;
import com.khoga.common.model.enums.PaymentMethod;
import com.khoga.common.model.enums.PaymentStatus;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/** Full order view (UC-73): header + payment + line items with toppings. */
public record OrderDetailResponse(
        UUID id,
        String orderNumber,
        UUID storeId,
        OrderStatus status,
        PaymentStatus paymentStatus,
        PaymentMethod paymentMethod,
        OrderType orderType,
        BigDecimal subtotal,
        BigDecimal discount,
        BigDecimal taxAmount,
        BigDecimal total,
        Integer pointsRedeemed,
        Integer pointsEarned,
        String customerName,
        List<OrderItemLine> items,
        LocalDateTime createdAt) {
}
