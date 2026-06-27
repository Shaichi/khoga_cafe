package com.khoga.staff.dto;

import com.khoga.common.model.enums.AttendanceStatus;

/** BR-91 derived attendance metrics for one schedule/log pairing. All durations in minutes. */
public record AttendanceMetrics(
        AttendanceStatus status,
        long lateMinutes,
        long earlyLeaveMinutes,
        long overtimeMinutes,
        long workedMinutes) {
}
