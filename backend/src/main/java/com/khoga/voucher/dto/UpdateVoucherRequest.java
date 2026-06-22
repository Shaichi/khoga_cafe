package com.khoga.voucher.dto;

import com.khoga.common.model.enums.DiscountType;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/** {@code code} is intentionally absent — it is immutable (BR-40/UC-22). */
public record UpdateVoucherRequest(
        @NotNull DiscountType discountType,
        @NotNull @Positive(message = "Giá trị giảm phải lớn hơn 0") BigDecimal discountValue,
        @PositiveOrZero BigDecimal minOrderValue,
        LocalDateTime startDate,
        LocalDateTime endDate,
        @PositiveOrZero BigDecimal maxDiscountAmount,
        Integer usageLimitPerCustomer,
        Integer maxTotalUses,
        Boolean active) {
}
