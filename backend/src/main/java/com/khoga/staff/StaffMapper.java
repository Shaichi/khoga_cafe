package com.khoga.staff;

import com.khoga.common.model.AttendanceLog;
import com.khoga.common.model.StaffSchedule;
import com.khoga.common.model.User;
import com.khoga.staff.dto.AttendanceResponse;
import com.khoga.staff.dto.ScheduleResponse;
import com.khoga.staff.dto.StaffRosterResponse;

import org.springframework.util.StringUtils;

/** Hand-written Staff entity → DTO mappers (per CLAUDE.md convention). */
final class StaffMapper {

    private StaffMapper() {
    }

    static ScheduleResponse toScheduleResponse(StaffSchedule s, boolean crossBranch) {
        User u = s.getUser();
        return new ScheduleResponse(
                s.getId(),
                u != null ? u.getId() : null,
                u != null ? u.getFullName() : null,
                u != null ? u.getRole() : null,
                s.getShiftDate(),
                s.getShiftType(),
                s.getShiftStartTime(),
                s.getShiftEndTime(),
                s.getPosRegisterId(),
                crossBranch);
    }

    static StaffRosterResponse toRoster(User u, boolean pinLocked) {
        return new StaffRosterResponse(
                u.getId(),
                u.getEmployeeId(),
                u.getFullName(),
                u.getRole(),
                StringUtils.hasText(u.getAttendancePin()),
                pinLocked,
                u.getIsActive());
    }

    static AttendanceResponse toAttendanceResponse(AttendanceLog log) {
        User u = log.getUser();
        return new AttendanceResponse(
                log.getId(),
                u != null ? u.getId() : null,
                u != null ? u.getFullName() : null,
                log.getShiftDate(),
                log.getCheckInAt(),
                log.getCheckOutAt(),
                log.getScheduledStart(),
                log.getStatus(),
                Boolean.TRUE.equals(log.getPendingVerification()),
                StringUtils.hasText(log.getPhotoUrl()));
    }
}
