package com.khoga.pos.dto;

import jakarta.validation.constraints.NotNull;

import java.util.UUID;

/** VietQR gateway webhook payload (BR-84/BR-85). The real signature field arrives in P4. */
public record VietQrCallbackRequest(
        @NotNull UUID orderId,
        String reference,
        String signature,
        String transactionId) {
}
