package com.khoga.staff.dto;

import com.khoga.common.model.enums.AttendanceStatus;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/** UC-39/80 report row: one scheduled shift joined with its log + derived metrics (BR-91). */
public record AttendanceReportRow(
        UUID userId,
        String employeeName,
        LocalDate shiftDate,
        LocalDateTime scheduledStart,
        LocalDateTime scheduledEnd,
        LocalDateTime checkInAt,
        LocalDateTime checkOutAt,
        AttendanceStatus status,
        long lateMinutes,
        long earlyLeaveMinutes,
        long overtimeMinutes,
        long workedMinutes) {
}
