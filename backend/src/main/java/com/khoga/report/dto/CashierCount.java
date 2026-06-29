package com.khoga.report.dto;

import java.util.UUID;

/** Internal projection: a per-cashier event count (orders / cancellations / refunds / etc.) for UC-82. */
public record CashierCount(UUID cashierId, long count) {
}
