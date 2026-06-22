package com.khoga.integration;

import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;

/**
 * Dev/test printer adapter — logs receipts/labels instead of printing. Active on every profile
 * except {@code prod}.
 */
@Slf4j
@Service
@Profile("!prod")
public class PrinterServiceStub implements PrinterService {

    @Override
    public void printReceipt(String content) {
        log.info("[PRINTER-STUB] RECEIPT:\n{}", content);
    }

    @Override
    public void printLabel(String content) {
        log.info("[PRINTER-STUB] LABEL: {}", content);
    }
}
