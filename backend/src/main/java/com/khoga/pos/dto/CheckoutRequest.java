package com.khoga.pos.dto;

import com.khoga.common.model.enums.PaymentMethod;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import com.khoga.common.model.enums.OrderType;

/** Stateless checkout: the client sends the whole cart at submit (UC-45→51). */
public record CheckoutRequest(
        UUID customerId,
        String voucherCode,
        @PositiveOrZero int redeemPoints,
        @NotNull PaymentMethod paymentMethod,
        OrderType orderType,
        BigDecimal cashReceived,
        @NotEmpty @Valid List<CartLineRequest> items) {
}
