package com.khoga.pos.dto;

import com.khoga.common.model.enums.OrderStatus;
import com.khoga.common.model.enums.PaymentMethod;
import com.khoga.common.model.enums.PaymentStatus;

import java.math.BigDecimal;
import java.util.UUID;

/** Checkout result: the created order, the BR-70 breakdown, and either cash change or a VietQR code. */
public record CheckoutResponse(
        UUID orderId,
        String orderNumber,
        OrderStatus status,
        PaymentStatus paymentStatus,
        PaymentMethod paymentMethod,
        DiscountBreakdown breakdown,
        BigDecimal changeDue,
        String qrContent,
        String qrReference) {
}
