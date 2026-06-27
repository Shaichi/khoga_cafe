package com.khoga.pos.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;

import java.math.BigDecimal;

/** UC-44 open shift — opening cash float must be ≥ 0 (BR-33). */
public record OpenShiftRequest(
        @NotBlank String posRegisterId,
        @NotNull @PositiveOrZero BigDecimal startingCash) {
}
