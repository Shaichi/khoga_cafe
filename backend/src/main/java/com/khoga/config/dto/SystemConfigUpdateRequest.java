package com.khoga.config.dto;

import jakarta.validation.constraints.NotNull;

/** Update the value of one GLOBAL config key (UC-24). The key comes from the path. */
public record SystemConfigUpdateRequest(
        @NotNull(message = "Giá trị không được để trống") String value) {
}
