package com.khoga.pos.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;

import java.math.BigDecimal;

/** UC-53 close shift — counted closing cash. */
public record CloseShiftRequest(
        @NotNull @PositiveOrZero BigDecimal closingCash,
        String discrepancyNotes) {
}
