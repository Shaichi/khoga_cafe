package com.khoga.staff.dto;

import com.khoga.common.model.enums.ShiftType;
import jakarta.validation.constraints.NotNull;

import java.time.LocalTime;

/** UC-37 edit a shift (BR-36: a past shift is read-only). The shift date itself is fixed. */
public record UpdateScheduleRequest(
        @NotNull ShiftType shiftType,
        @NotNull LocalTime shiftStartTime,
        @NotNull LocalTime shiftEndTime,
        String posRegisterId,
        String overrideReason) {
}
