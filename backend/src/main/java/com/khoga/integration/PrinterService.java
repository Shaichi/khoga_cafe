package com.khoga.integration;

/**
 * Receipt/label printer port. The default {@link PrinterServiceStub} logs; a real ESC/POS adapter
 * (USB/network) lands in P4.
 */
public interface PrinterService {

    void printReceipt(String content);

    void printLabel(String content);
}
