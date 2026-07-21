package com.khoga.pos.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/** UC-53 close-shift reconciliation summary (Z-report core). */
public record ZReportResponse(
        UUID sessionId,
        String posRegisterId,
        BigDecimal openingCash,
        BigDecimal totalCashSales,
        BigDecimal totalCardSales,
        BigDecimal totalVietQrSales,
        BigDecimal expectedCash,
        BigDecimal closingCash,
        BigDecimal discrepancy,
        boolean discrepancyFlagged,
        long totalOrders,
        long cancelledOrders,
        LocalDateTime startTime,
        LocalDateTime closedAt) {
}
