package com.khoga.pos.dto;

import java.math.BigDecimal;

/** Snapshot of the loyalty/tax config used for one checkout (BR-46 — captured at order time). */
public record DiscountConfig(
        BigDecimal vatRate,
        BigDecimal valuePerPoint,
        BigDecimal maxRedeemPercent,
        BigDecimal maxRedeemLimit,
        BigDecimal accrualPercent) {
}
