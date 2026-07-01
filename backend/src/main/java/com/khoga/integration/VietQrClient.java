package com.khoga.integration;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * VietQR payment port. The default {@link VietQrClientStub} fabricates a deterministic QR; the real
 * client + signed webhook verification land in P4.
 */
public interface VietQrClient {

    /** Idempotency key = orderId (BR-84): calling twice for the same order yields the same QR. */
    VietQrPayment generateQr(UUID orderId, BigDecimal amount);

    /**
     * Verifies the gateway webhook HMAC signature (RDS §3.7.4 — VietQRClient owns signature checking,
     * not the controller). {@code payload} is the canonical string the gateway signed; returns true iff
     * {@code signature} matches the HMAC computed with the shared webhook secret.
     */
    boolean verifyWebhookSignature(String payload, String signature);
}
