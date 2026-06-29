package com.khoga.report.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * UC-28 consolidated chain dashboard: totals + per-branch comparison + best sellers + cancellation
 * rate over a date range (COMPLETED orders only).
 */
public record HqConsolidatedReport(
        LocalDate from,
        LocalDate to,
        BigDecimal totalRevenue,
        long totalOrders,
        BigDecimal avgTransactionValue,
        BigDecimal cancellationRate,
        List<BranchRevenueRow> branches,
        List<BestSellerRow> bestSellers) {
}
