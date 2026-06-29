package com.khoga.report.dto;

import java.math.BigDecimal;

/** Internal projection: summed order money + redeemed points for a branch/day (UC-81 Z-report). */
public record OrderTotalsAccum(
        BigDecimal gross,
        BigDecimal discount,
        BigDecimal tax,
        BigDecimal net,
        long pointsRedeemed) {
}
