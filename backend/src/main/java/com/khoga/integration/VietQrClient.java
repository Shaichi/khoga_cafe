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
}
