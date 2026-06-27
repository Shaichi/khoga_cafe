package com.khoga.pos;

import com.khoga.customer.LoyaltyPointCalculator;
import com.khoga.pos.dto.DiscountBreakdown;
import com.khoga.pos.dto.DiscountConfig;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * BR-70 discount &amp; tax stacking pipeline (authoritative §3.6.6.3). Fixed order:
 * <ol>
 *   <li>Gross subtotal</li>
 *   <li>Voucher discount (already capped by {@code VoucherValidationService}; never exceeds gross, BR-50)</li>
 *   <li>Loyalty redemption — raw value, capped by %/absolute (BR-02) and by the remaining subtotal (BR-50)</li>
 *   <li>VAT extraction (inclusive): {@code tax = final × rate / (100 + rate)}</li>
 *   <li>Net Total Payable = the VAT-inclusive final taxable subtotal (≥ 0)</li>
 *   <li>Accrual computed on Net Total Payable (BR-69)</li>
 * </ol>
 * Pure: the caller passes a snapshot {@link DiscountConfig} (BR-46) so the result is deterministic.
 */
@Component
public class DiscountStackingEngine {

    private static final BigDecimal HUNDRED = BigDecimal.valueOf(100);

    private final LoyaltyPointCalculator loyalty;

    public DiscountStackingEngine(LoyaltyPointCalculator loyalty) {
        this.loyalty = loyalty;
    }

    public DiscountBreakdown compute(BigDecimal grossSubtotal, BigDecimal voucherDiscount,
                                     int redeemPoints, DiscountConfig config) {
        BigDecimal gross = nz(grossSubtotal);
        int points = Math.max(redeemPoints, 0);

        // (2) voucher — never below 0, never above gross (BR-50)
        BigDecimal voucher = nz(voucherDiscount).max(BigDecimal.ZERO).min(gross);
        BigDecimal discounted = gross.subtract(voucher);

        // (3) loyalty redemption — raw value, capped by %/absolute (BR-02) then by remaining subtotal (BR-50)
        BigDecimal rawPoint = loyalty.redeemValue(points, config.valuePerPoint());
        BigDecimal cap = loyalty.maxRedeemableValue(discounted, config.maxRedeemPercent(), config.maxRedeemLimit());
        BigDecimal pointDiscount = rawPoint.min(cap).min(discounted).max(BigDecimal.ZERO);
        BigDecimal finalTaxable = discounted.subtract(pointDiscount); // ≥ 0 by construction

        // (4) VAT inclusive extraction
        BigDecimal vatRate = nz(config.vatRate());
        BigDecimal tax = vatRate.signum() == 0
                ? BigDecimal.ZERO
                : finalTaxable.multiply(vatRate).divide(vatRate.add(HUNDRED), 0, RoundingMode.HALF_UP);

        // (5) Net Total Payable = VAT-inclusive final taxable subtotal
        BigDecimal net = finalTaxable;

        // (6) accrual on Net Total Payable (BR-69)
        int earned = loyalty.calcEarned(net, config.accrualPercent());

        return new DiscountBreakdown(gross, voucher, points, pointDiscount, finalTaxable, tax, net, earned);
    }

    private static BigDecimal nz(BigDecimal v) {
        return v == null ? BigDecimal.ZERO : v;
    }
}
