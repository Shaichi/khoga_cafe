package com.khoga.report.dto;

import java.math.BigDecimal;

/**
 * Per-day revenue aggregate (COMPLETED orders) used to build the HQ consolidated trend. Kept as
 * year/month/day integers so the JPQL relies only on the standard {@code year()/month()/day()}
 * functions (no {@code cast}); the service reassembles a {@code LocalDate} and re-buckets by granularity.
 */
public record DailyRevenueRow(Integer year, Integer month, Integer day, BigDecimal revenue, long orders) {
}
