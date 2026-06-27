package com.khoga.order.dto;

import com.khoga.common.model.enums.OrderStatus;
import com.khoga.common.model.enums.OrderType;
import com.khoga.common.model.enums.PaymentMethod;
import com.khoga.common.model.enums.PaymentStatus;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/** Row in the barista queue (UC-57) and order history (UC-54). */
public record OrderSummaryResponse(
        UUID id,
        String orderNumber,
        OrderStatus status,
        PaymentStatus paymentStatus,
        PaymentMethod paymentMethod,
        OrderType orderType,
        BigDecimal total,
        int itemCount,
        String customerName,
        LocalDateTime createdAt) {
}
