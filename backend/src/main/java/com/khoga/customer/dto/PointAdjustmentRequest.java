package com.khoga.customer.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/** BR-49: a manual point adjustment must carry a reason and is audited. */
public record PointAdjustmentRequest(
        @NotNull(message = "Số điểm điều chỉnh không được để trống") Integer delta,
        @NotBlank(message = "Phải nhập lý do điều chỉnh điểm") String reason) {
}
