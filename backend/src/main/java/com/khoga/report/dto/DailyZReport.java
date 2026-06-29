package com.khoga.report.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

/**
 * UC-81 daily Z-report (BR-78): one branch, one business day, all shifts aggregated. Sales block
 * (gross → net → VAT → refunds), tender breakdown, and counters. {@code provisional} is true when a
 * shift in the day is still OPEN (figures not yet final).
 */
public record DailyZReport(
        LocalDate businessDay,
        UUID storeId,
        BigDecimal grossSales,
        BigDecimal voucherDiscount,
        BigDecimal pointDiscount,
        BigDecimal netSales,
        BigDecimal vat,
        BigDecimal refunds,
        PaymentBreakdown tender,
        long ordersCompleted,
        long refundCount,
        long pendingCancellations,
        int shiftsInDay,
        boolean provisional) {
}
