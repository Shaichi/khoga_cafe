package com.khoga.staff.dto;

import com.khoga.common.model.enums.Role;
import com.khoga.common.model.enums.ShiftType;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

/** A scheduled shift (UC-35). {@code crossBranch} = the employee's home branch differs from this one (BR-90). */
public record ScheduleResponse(
        UUID id,
        UUID employeeId,
        String employeeName,
        Role role,
        LocalDate shiftDate,
        ShiftType shiftType,
        LocalTime shiftStartTime,
        LocalTime shiftEndTime,
        String posRegisterId,
        boolean crossBranch) {
}
