package com.khoga.report.dto;

import java.math.BigDecimal;
import java.util.UUID;

/** One branch's revenue + completed-order count for the HQ consolidated dashboard (UC-28). */
public record BranchRevenueRow(UUID storeId, String storeName, BigDecimal revenue, long orders) {
}
