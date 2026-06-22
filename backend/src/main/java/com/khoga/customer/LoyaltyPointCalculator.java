package com.khoga.customer;

import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Loyalty arithmetic shared by POS accrual/redemption (UC-49) and order rollback. Pure functions —
 * callers supply the config values (accrual %, value-per-point, caps) so this stays deterministic.
 *
 * <ul>
 *   <li>BR-01/BR-69: earned points = floor(netTotalPayable × accrual% / 100).</li>
 *   <li>BR-74: redeemed cash value = points × valuePerPoint.</li>
 *   <li>BR-02: redeemable value is capped by a percentage of the order and/or an absolute amount.</li>
 * </ul>
 */
@Component
public class LoyaltyPointCalculator {

    public int calcEarned(BigDecimal netTotalPayable, BigDecimal accrualPercent) {
        if (netTotalPayable == null || accrualPercent == null) {
            return 0;
        }
        BigDecimal earned = netTotalPayable.multiply(accrualPercent)
                .divide(BigDecimal.valueOf(100), 0, RoundingMode.FLOOR);     // BR-01 floor
        if (earned.signum() < 0) {
            return 0;
        }
        return earned.intValueExact();
    }

    public BigDecimal redeemValue(int points, BigDecimal valuePerPoint) {
        if (points <= 0 || valuePerPoint == null) {
            return BigDecimal.ZERO;
        }
        return valuePerPoint.multiply(BigDecimal.valueOf(points));            // BR-74
    }

    /** BR-02: smallest of (percentage-of-subtotal, absolute) cap; null bounds are ignored. */
    public BigDecimal maxRedeemableValue(BigDecimal subtotal, BigDecimal maxPercent, BigDecimal maxAbsolute) {
        BigDecimal cap = null;
        if (maxPercent != null && subtotal != null) {
            cap = subtotal.multiply(maxPercent).divide(BigDecimal.valueOf(100), 0, RoundingMode.FLOOR);
        }
        if (maxAbsolute != null) {
            cap = (cap == null) ? maxAbsolute : cap.min(maxAbsolute);
        }
        return cap == null ? subtotal : cap;
    }
}
