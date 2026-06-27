package com.khoga.pos.dto;

import java.math.BigDecimal;

/** Result of the BR-70 stacking pipeline. {@code netTotalPayable} equals {@code finalTaxableSubtotal} (VAT-inclusive). */
public record DiscountBreakdown(
        BigDecimal grossSubtotal,
        BigDecimal voucherDiscount,
        int pointsRedeemed,
        BigDecimal pointDiscount,
        BigDecimal finalTaxableSubtotal,
        BigDecimal taxAmount,
        BigDecimal netTotalPayable,
        int pointsEarned) {
}
