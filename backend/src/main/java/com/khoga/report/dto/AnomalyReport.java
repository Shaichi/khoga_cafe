package com.khoga.report.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * UC-82 cashier void/refund anomaly report. {@code thresholdPercent} is the configured
 * {@code CANCEL_REFUND_ALERT_THRESHOLD} (BR-79); rows exceeding it on cancel or refund rate are flagged.
 */
public record AnomalyReport(
        LocalDate from,
        LocalDate to,
        UUID branchId,
        BigDecimal thresholdPercent,
        List<CashierAnomalyRow> cashiers) {
}
