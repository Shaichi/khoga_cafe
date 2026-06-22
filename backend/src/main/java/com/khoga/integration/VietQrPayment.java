package com.khoga.integration;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Result of a VietQR generation request. {@code reference} is derived from the order id so that
 * repeated requests for the same order are idempotent (BR-84).
 */
public record VietQrPayment(UUID orderId, BigDecimal amount, String qrContent, String reference) {
}
