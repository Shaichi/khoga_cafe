package com.khoga.staff;

import com.khoga.common.model.enums.AttendanceStatus;
import com.khoga.staff.dto.AttendanceMetrics;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.assertEquals;

/** P2.4 arithmetic tests for BR-91 attendance metric derivation. */
class AttendanceMetricsCalculatorTest {

    private final AttendanceMetricsCalculator calc = new AttendanceMetricsCalculator();

    private LocalDateTime at(int hour, int minute) {
        return LocalDateTime.of(2026, 6, 27, hour, minute);
    }

    @Test
    void scheduledButNoLog_isAbsent() {
        AttendanceMetrics m = calc.derive(at(8, 0), at(16, 0), null, null, 5);
        assertEquals(AttendanceStatus.ABSENT, m.status());
        assertEquals(0, m.workedMinutes());
    }

    @Test
    void lateBeyondGrace_isLate() {
        AttendanceMetrics m = calc.derive(at(8, 0), at(16, 0), at(8, 30), at(16, 0), 5);
        assertEquals(AttendanceStatus.LATE, m.status());
        assertEquals(30, m.lateMinutes());
    }

    @Test
    void withinGrace_isPresent() {
        AttendanceMetrics m = calc.derive(at(8, 0), at(16, 0), at(8, 3), at(16, 0), 5);
        assertEquals(AttendanceStatus.PRESENT, m.status());
        assertEquals(0, m.lateMinutes());
    }

    @Test
    void workedBeyondScheduled_isOvertime() {
        AttendanceMetrics m = calc.derive(at(8, 0), at(16, 0), at(8, 0), at(18, 0), 5);
        assertEquals(600, m.workedMinutes());
        assertEquals(120, m.overtimeMinutes());
    }

    @Test
    void leftBeforeScheduledEnd_isEarlyLeave() {
        AttendanceMetrics m = calc.derive(at(8, 0), at(16, 0), at(8, 0), at(15, 0), 5);
        assertEquals(60, m.earlyLeaveMinutes());
        assertEquals(420, m.workedMinutes());
    }
}
