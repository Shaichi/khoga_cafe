package com.khoga.pos;

import com.khoga.customer.LoyaltyPointCalculator;
import com.khoga.pos.dto.DiscountBreakdown;
import com.khoga.pos.dto.DiscountConfig;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.assertEquals;

/** P2.2 unit tests for the BR-70 stacking pipeline (uses the real pure LoyaltyPointCalculator). */
class DiscountStackingEngineTest {

    private final DiscountStackingEngine engine = new DiscountStackingEngine(new LoyaltyPointCalculator());

    @Test
    void fullPipeline_voucherThenPointsThenVatThenAccrual() {
        // gross 100k, voucher 10k → discounted 90k; redeem 200pt×100 = 20k (cap 50% = 45k) → point 20k
        // finalTaxable 70k; VAT 10 → tax = 70000×10/110 = 6364 (HALF_UP); net 70k; accrual 1% → 700
        DiscountConfig cfg = new DiscountConfig(new BigDecimal("10"), new BigDecimal("100"),
                new BigDecimal("50"), new BigDecimal("100000"), new BigDecimal("1"));

        DiscountBreakdown b = engine.compute(new BigDecimal("100000"), new BigDecimal("10000"), 200, cfg);

        assertEquals(0, b.voucherDiscount().compareTo(new BigDecimal("10000")));
        assertEquals(0, b.pointDiscount().compareTo(new BigDecimal("20000")));
        assertEquals(0, b.finalTaxableSubtotal().compareTo(new BigDecimal("70000")));
        assertEquals(0, b.taxAmount().compareTo(new BigDecimal("6364")));
        assertEquals(0, b.netTotalPayable().compareTo(new BigDecimal("70000")));
        assertEquals(700, b.pointsEarned());
    }

    @Test
    void redemptionCappedByPercent() {
        // gross 100k, no voucher; redeem 1000pt×100 = 100k but capped at 50% = 50k; VAT 0
        DiscountConfig cfg = new DiscountConfig(BigDecimal.ZERO, new BigDecimal("100"),
                new BigDecimal("50"), null, new BigDecimal("1"));

        DiscountBreakdown b = engine.compute(new BigDecimal("100000"), BigDecimal.ZERO, 1000, cfg);

        assertEquals(0, b.pointDiscount().compareTo(new BigDecimal("50000")));
        assertEquals(0, b.netTotalPayable().compareTo(new BigDecimal("50000")));
        assertEquals(0, b.taxAmount().compareTo(BigDecimal.ZERO));
    }

    @Test
    void netNeverNegative_BR50() {
        // voucher 60k > gross 50k → capped to 50k; nothing left for points; net 0, earns 0
        DiscountConfig cfg = new DiscountConfig(new BigDecimal("10"), new BigDecimal("100"),
                new BigDecimal("50"), null, new BigDecimal("1"));

        DiscountBreakdown b = engine.compute(new BigDecimal("50000"), new BigDecimal("60000"), 500, cfg);

        assertEquals(0, b.voucherDiscount().compareTo(new BigDecimal("50000")));
        assertEquals(0, b.pointDiscount().compareTo(BigDecimal.ZERO));
        assertEquals(0, b.netTotalPayable().compareTo(BigDecimal.ZERO));
        assertEquals(0, b.pointsEarned());
    }
}
