package com.khoga.order.dto;

import com.khoga.common.model.enums.PaymentStatus;
import com.khoga.common.model.enums.RefundType;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Result of UC-75. For a REFUND the original order is flagged REFUNDED; for a COMP_REMAKE a fresh
 * PENDING clone is queued and its id returned in {@code remakeOrderId}.
 */
public record RefundResponse(
        UUID refundId,
        UUID orderId,
        RefundType refundType,
        BigDecimal amount,
        PaymentStatus orderPaymentStatus,
        UUID remakeOrderId) {
}
