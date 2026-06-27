package com.khoga.staff.dto;

import com.khoga.common.model.enums.ShiftType;
import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

/**
 * UC-36 create a shift for an employee. {@code posRegisterId} is mandatory when the employee's role is
 * CASHIER (A46). {@code overrideReason} is required only when the soft labour budget is exceeded (BR-92).
 */
public record CreateScheduleRequest(
        @NotNull UUID employeeId,
        @NotNull LocalDate shiftDate,
        @NotNull ShiftType shiftType,
        @NotNull LocalTime shiftStartTime,
        @NotNull LocalTime shiftEndTime,
        String posRegisterId,
        String overrideReason) {
}
