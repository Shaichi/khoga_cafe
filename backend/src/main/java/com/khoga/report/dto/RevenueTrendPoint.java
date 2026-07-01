package com.khoga.report.dto;

import java.math.BigDecimal;

/**
 * One point on the HQ consolidated revenue time-series (UC-28/29 date granularity). {@code period} is
 * the bucket label — {@code yyyy-MM-dd} (daily), {@code yyyy-Www} (weekly) or {@code yyyy-MM} (monthly).
 */
public record RevenueTrendPoint(String period, BigDecimal revenue, long orders) {
}
