package com.khoga.customer;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.assertEquals;

/** P1.5 unit tests for loyalty arithmetic (BR-01/02/74). */
class LoyaltyPointCalculatorTest {

    private final LoyaltyPointCalculator calculator = new LoyaltyPointCalculator();

    @Test
    void calcEarnedFloorsTheResult() {
        // 1% of 99,999 = 999.99 → floor 999
        assertEquals(999, calculator.calcEarned(new BigDecimal("99999"), new BigDecimal("1")));
    }

    @Test
    void calcEarnedExactValue() {
        assertEquals(1000, calculator.calcEarned(new BigDecimal("100000"), new BigDecimal("1")));
    }

    @Test
    void redeemValueIsPointsTimesValuePerPoint() {
        assertEquals(0, calculator.redeemValue(10, new BigDecimal("100")).compareTo(new BigDecimal("1000")));
    }

    @Test
    void maxRedeemableTakesSmallerOfPercentAndAbsolute() {
        // 50% of 100,000 = 50,000 vs absolute 30,000 → 30,000
        assertEquals(0, calculator.maxRedeemableValue(
                new BigDecimal("100000"), new BigDecimal("50"), new BigDecimal("30000"))
                .compareTo(new BigDecimal("30000")));
    }

    @Test
    void maxRedeemablePercentOnlyWhenNoAbsolute() {
        assertEquals(0, calculator.maxRedeemableValue(
                new BigDecimal("100000"), new BigDecimal("50"), null)
                .compareTo(new BigDecimal("50000")));
    }
}
