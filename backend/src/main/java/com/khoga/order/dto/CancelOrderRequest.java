package com.khoga.order.dto;

import jakarta.validation.constraints.NotBlank;

/** UC-55 cancel a PENDING order (BR-05). The reason is mandatory and logged immutably (BR-51). */
public record CancelOrderRequest(
        @NotBlank String reason,
        String notes) {
}
