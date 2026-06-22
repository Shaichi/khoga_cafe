package com.khoga.voucher.dto;

import com.khoga.common.model.enums.DiscountType;
import com.khoga.voucher.VoucherStatus;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

public record VoucherResponse(
        UUID id, String code, DiscountType discountType, BigDecimal discountValue,
        BigDecimal minOrderValue, LocalDateTime startDate, LocalDateTime endDate,
        BigDecimal maxDiscountAmount, Integer usageLimitPerCustomer, Integer maxTotalUses,
        Integer totalUsageCount, VoucherStatus status) {
}
