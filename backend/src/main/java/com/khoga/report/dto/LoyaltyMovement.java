package com.khoga.report.dto;

/**
 * UC-78 loyalty point movement for a period, in points (BR-75):
 * {@code opening + issued − redeemed − expired = closing}.
 */
public record LoyaltyMovement(long opening, long issued, long redeemed, long expired, long closing) {
}
