package com.khoga.report.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

/**
 * UC-40 local branch revenue summary: net revenue, completed-order count, cash-drawer discrepancy
 * total across the period's closed shifts, and a payment-method breakdown.
 */
public record StoreRevenueReport(
        LocalDate from,
        LocalDate to,
        UUID storeId,
        BigDecimal netRevenue,
        long completedOrders,
        BigDecimal discrepancyTotal,
        PaymentBreakdown payments) {
}
