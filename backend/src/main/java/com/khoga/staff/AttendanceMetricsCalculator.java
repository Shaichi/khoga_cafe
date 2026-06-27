package com.khoga.staff;

import com.khoga.common.model.enums.AttendanceStatus;
import com.khoga.staff.dto.AttendanceMetrics;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.LocalDateTime;

/**
 * BR-39/BR-91 — derives attendance metrics (lateness, early-leave, overtime, worked minutes) from a
 * scheduled shift and its check-in/out log. Pure and stateless; the reporting layer calls it per
 * pairing rather than storing the derived values. Lateness uses a configurable grace window.
 */
@Component
public class AttendanceMetricsCalculator {

    public AttendanceMetrics derive(LocalDateTime scheduledStart, LocalDateTime scheduledEnd,
                                    LocalDateTime checkInAt, LocalDateTime checkOutAt, long lateGraceMinutes) {
        if (checkInAt == null) {
            return new AttendanceMetrics(AttendanceStatus.ABSENT, 0, 0, 0, 0); // scheduled but never showed
        }

        long lateMinutes = 0;
        AttendanceStatus status = AttendanceStatus.PRESENT;
        if (scheduledStart != null && checkInAt.isAfter(scheduledStart)) {
            long minsLate = minutesBetween(scheduledStart, checkInAt);
            if (minsLate > lateGraceMinutes) {
                lateMinutes = minsLate;
                status = AttendanceStatus.LATE;
            }
        }

        long workedMinutes = checkOutAt == null ? 0 : minutesBetween(checkInAt, checkOutAt);

        long earlyLeaveMinutes = 0;
        long overtimeMinutes = 0;
        if (checkOutAt != null && scheduledEnd != null) {
            if (checkOutAt.isBefore(scheduledEnd)) {
                earlyLeaveMinutes = minutesBetween(checkOutAt, scheduledEnd);
            }
            if (scheduledStart != null) {
                long scheduledMinutes = minutesBetween(scheduledStart, scheduledEnd);
                overtimeMinutes = Math.max(0, workedMinutes - scheduledMinutes);
            }
        }
        return new AttendanceMetrics(status, lateMinutes, earlyLeaveMinutes, overtimeMinutes, workedMinutes);
    }

    private static long minutesBetween(LocalDateTime from, LocalDateTime to) {
        return Math.max(0, Duration.between(from, to).toMinutes());
    }
}
