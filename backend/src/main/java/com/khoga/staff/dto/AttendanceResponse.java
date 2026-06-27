package com.khoga.staff.dto;

import com.khoga.common.model.enums.AttendanceStatus;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/** A single attendance pairing (UC-67). */
public record AttendanceResponse(
        UUID id,
        UUID userId,
        String employeeName,
        LocalDate shiftDate,
        LocalDateTime checkInAt,
        LocalDateTime checkOutAt,
        LocalDateTime scheduledStart,
        AttendanceStatus status,
        boolean pendingVerification,
        boolean photoCaptured) {
}
