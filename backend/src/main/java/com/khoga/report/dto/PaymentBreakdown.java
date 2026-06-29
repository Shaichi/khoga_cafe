package com.khoga.report.dto;

import java.math.BigDecimal;

/** Sales collected by tender type (UC-40 store revenue, UC-81 Z-report). */
public record PaymentBreakdown(BigDecimal cash, BigDecimal card, BigDecimal vietqr) {

    public BigDecimal total() {
        return cash.add(card).add(vietqr);
    }
}
