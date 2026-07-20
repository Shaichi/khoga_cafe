package com.khoga.catalog.dto;

import jakarta.validation.constraints.NotNull;

public record MenuItemStatusRequest(
                @NotNull(message = "Trạng thái không được để trống") Boolean active) {
}