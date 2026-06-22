package com.khoga.catalog.dto;

import jakarta.validation.constraints.NotNull;

import java.util.UUID;

/** UC-19 / BR-25: per-branch availability toggle for a menu item. */
public record AvailabilityRequest(
        @NotNull(message = "Chi nhánh không được để trống") UUID storeId,
        @NotNull(message = "Trạng thái không được để trống") Boolean available) {
}
