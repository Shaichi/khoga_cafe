package com.khoga.integration;

import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Dev/test VietQR adapter — fabricates a deterministic QR keyed by order id (idempotent, BR-84).
 * Active on every profile except {@code prod}.
 */
@Slf4j
@Service
@Profile("!prod")
public class VietQrClientStub implements VietQrClient {

    @Override
    public VietQrPayment generateQr(UUID orderId, BigDecimal amount) {
        String reference = "STUBQR-" + orderId;
        String qrContent = "00020101021238" + reference + "5303704" + amount;
        log.info("[VIETQR-STUB] order={} amount={} ref={}", orderId, amount, reference);
        return new VietQrPayment(orderId, amount, qrContent, reference);
    }
}
