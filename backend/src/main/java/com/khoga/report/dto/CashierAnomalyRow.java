package com.khoga.report.dto;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * UC-82 per-cashier void/refund activity for the anomaly report (BR-79): order volume, cancellations
 * (count + % of orders), refunds (count + % of orders), vouchers applied, comps, and the anomaly flag.
 */
public record CashierAnomalyRow(
        UUID cashierId,
        String cashierName,
        long orders,
        long cancellations,
        BigDecimal cancelRate,
        long refunds,
        BigDecimal refundRate,
        long vouchers,
        long comps,
        boolean flagged) {
}
