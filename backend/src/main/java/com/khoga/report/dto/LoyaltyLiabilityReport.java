package com.khoga.report.dto;

import java.time.LocalDate;
import java.util.UUID;

/**
 * UC-78 loyalty liability & movement report (BR-75). Outstanding balance is chain-wide; movement is
 * over the period and optionally branch-scoped. Reported in points (not VND).
 */
public record LoyaltyLiabilityReport(
        LocalDate from,
        LocalDate to,
        UUID branchId,
        long outstandingPoints,
        LoyaltyMovement movement,
        String note) {
}
