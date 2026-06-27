package com.khoga.order.dto;

import com.khoga.common.model.enums.OrderStatus;
import jakarta.validation.constraints.NotNull;

/** Barista state transition (UC-58): the requested target state. */
public record UpdateStatusRequest(
        @NotNull OrderStatus status) {
}
