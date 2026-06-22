package com.khoga.voucher.dto;

import com.khoga.common.model.enums.DiscountType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record CreateVoucherRequest(
        @NotBlank(message = "Mã voucher không được để trống") String code,
        @NotNull(message = "Loại giảm giá không được để trống") DiscountType discountType,
        @NotNull @Positive(message = "Giá trị giảm phải lớn hơn 0") BigDecimal discountValue,
        @PositiveOrZero BigDecimal minOrderValue,
        LocalDateTime startDate,
        LocalDateTime endDate,
        @PositiveOrZero BigDecimal maxDiscountAmount,
        Integer usageLimitPerCustomer,
        Integer maxTotalUses) {
}
