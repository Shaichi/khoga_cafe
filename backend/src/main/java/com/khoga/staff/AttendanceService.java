package com.khoga.staff;

import com.khoga.audit.AuditLogService;
import com.khoga.common.exception.AppException;
import com.khoga.common.exception.ResourceNotFoundException;
import com.khoga.common.model.AttendanceLog;
import com.khoga.common.model.StaffSchedule;
import com.khoga.common.model.Store;
import com.khoga.common.model.User;
import com.khoga.common.model.enums.ActionType;
import com.khoga.common.repository.AttendanceLogRepository;
import com.khoga.common.repository.StaffScheduleRepository;
import com.khoga.common.repository.UserRepository;
import com.khoga.config.SystemConfigService;
import com.khoga.staff.dto.AttendanceMetrics;
import com.khoga.staff.dto.AttendanceReportRow;
import com.khoga.staff.dto.AttendanceResponse;
import com.khoga.staff.dto.CheckInRequest;
import com.khoga.staff.dto.CheckOutRequest;
import com.khoga.staff.dto.VerifyAttendanceRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Attendance (UC-67 check-in/out, UC-39 report, UC-80 export) and the BR-72 photo purge. The employee
 * is identified by a branch-unique PIN (BR-93); a locked PIN is rejected and a successful entry resets
 * the lock. A missing photo queues the record for Store-Manager verification (BR-93 fallback). The
 * report derives lateness/OT/early-leave dynamically (BR-39/BR-91); worked-hours export is CSV (PDF
 * lands with the consolidated report exports in P3).
 */
@Slf4j
@Service
public class AttendanceService {

    private final AttendanceLogRepository attendanceLogRepository;
    private final StaffScheduleRepository scheduleRepository;
    private final UserRepository userRepository;
    private final SystemConfigService config;
    private final AttendanceMetricsCalculator metricsCalculator;
    private final AuditLogService auditLogService;

    public AttendanceService(AttendanceLogRepository attendanceLogRepository,
                             StaffScheduleRepository scheduleRepository, UserRepository userRepository,
                             SystemConfigService config, AttendanceMetricsCalculator metricsCalculator,
                             AuditLogService auditLogService) {
        this.attendanceLogRepository = attendanceLogRepository;
        this.scheduleRepository = scheduleRepository;
        this.userRepository = userRepository;
        this.config = config;
        this.metricsCalculator = metricsCalculator;
        this.auditLogService = auditLogService;
    }

    /** UC-67 check-in (BR-53/BR-93). Photoless check-ins are queued for SM verification. */
    @Transactional
    public AttendanceResponse checkIn(CheckInRequest req, UUID actorId) {
        Store store = currentUser(actorId).getStore();
        User employee = resolveByPin(store.getId(), req.pin());
        LocalDate today = LocalDate.now();
        if (attendanceLogRepository.existsByUserIdAndShiftDateAndCheckOutAtIsNull(employee.getId(), today)) {
            throw AppException.of("err.061");
        }

        LocalDateTime now = LocalDateTime.now();
        LocalDateTime scheduledStart = scheduleRepository.findByUserIdAndShiftDate(employee.getId(), today).stream()
                .findFirst()
                .map(s -> LocalDateTime.of(s.getShiftDate(), s.getShiftStartTime()))
                .orElse(null);
        long grace = config.getGlobalInt("ATTENDANCE_LATE_GRACE_MINUTES", 5);
        AttendanceMetrics m = metricsCalculator.derive(scheduledStart, null, now, null, grace);

        boolean hasPhoto = StringUtils.hasText(req.photoUrl());
        AttendanceLog logRow = new AttendanceLog();
        logRow.setStore(store);
        logRow.setUser(employee);
        logRow.setShiftDate(today);
        logRow.setCheckInAt(now);
        logRow.setScheduledStart(scheduledStart);
        logRow.setStatus(m.status());
        logRow.setPhotoUrl(hasPhoto ? req.photoUrl() : null);
        logRow.setPendingVerification(!hasPhoto); // BR-93 fallback when no photo
        AttendanceLog saved = attendanceLogRepository.save(logRow);

        clearPinLock(employee);
        if (!hasPhoto) {
            log.info("[BR-93] Photoless check-in for {} queued for SM verification", employee.getUsername());
        }
        return StaffMapper.toAttendanceResponse(saved);
    }

    /** UC-67 check-out — updates checkOutAt on the open pairing (same row, not a new event). */
    @Transactional
    public AttendanceResponse checkOut(CheckOutRequest req, UUID actorId) {
        Store store = currentUser(actorId).getStore();
        User employee = resolveByPin(store.getId(), req.pin());
        LocalDate today = LocalDate.now();
        AttendanceLog logRow = attendanceLogRepository
                .findFirstByUserIdAndShiftDateAndCheckOutAtIsNull(employee.getId(), today)
                .orElseThrow(() -> AppException.of("err.062"));
        logRow.setCheckOutAt(LocalDateTime.now());
        AttendanceLog saved = attendanceLogRepository.save(logRow);
        clearPinLock(employee);
        return StaffMapper.toAttendanceResponse(saved);
    }

    /** SM confirms a photoless check-in (BR-93 fallback); may attach the captured photo. */
    @Transactional
    public AttendanceResponse verifyPending(UUID logId, VerifyAttendanceRequest req, UUID actorId) {
        Store store = currentUser(actorId).getStore();
        AttendanceLog logRow = attendanceLogRepository.findById(logId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy bản chấm công"));
        if (logRow.getStore() == null || !logRow.getStore().getId().equals(store.getId())) {
            throw AppException.of("err.063"); // BR-59
        }
        if (!Boolean.TRUE.equals(logRow.getPendingVerification())) {
            throw AppException.of("err.064");
        }
        logRow.setPendingVerification(false);
        if (req != null && StringUtils.hasText(req.photoUrl())) {
            logRow.setPhotoUrl(req.photoUrl());
        }
        AttendanceLog saved = attendanceLogRepository.save(logRow);
        auditLogService.record(ActionType.UPDATE, "AttendanceVerification", null, logId.toString(), actorId);
        return StaffMapper.toAttendanceResponse(saved);
    }

    /** UC-39 — attendance report for the branch with BR-91 derived metrics. */
    @Transactional(readOnly = true)
    public List<AttendanceReportRow> getReport(LocalDate from, LocalDate to, UUID actorId) {
        UUID storeId = currentUser(actorId).getStore().getId();
        LocalDate start = from != null ? from : LocalDate.now().withDayOfMonth(1);
        LocalDate end = to != null ? to : LocalDate.now();
        long grace = config.getGlobalInt("ATTENDANCE_LATE_GRACE_MINUTES", 5);

        List<StaffSchedule> schedules = scheduleRepository.findByStoreIdAndShiftDateBetween(storeId, start, end);
        List<AttendanceLog> logs = attendanceLogRepository.findByStoreIdAndShiftDateBetween(storeId, start, end);
        Map<String, AttendanceLog> logByKey = new HashMap<>();
        for (AttendanceLog l : logs) {
            logByKey.put(key(l.getUser().getId(), l.getShiftDate()), l);
        }

        List<AttendanceReportRow> rows = new ArrayList<>();
        Set<String> covered = new HashSet<>();
        for (StaffSchedule s : schedules) {
            LocalDateTime schedStart = LocalDateTime.of(s.getShiftDate(), s.getShiftStartTime());
            LocalDateTime schedEnd = LocalDateTime.of(s.getShiftDate(), s.getShiftEndTime());
            String k = key(s.getUser().getId(), s.getShiftDate());
            AttendanceLog logRow = logByKey.get(k);
            covered.add(k);
            AttendanceMetrics m = metricsCalculator.derive(schedStart, schedEnd,
                    logRow != null ? logRow.getCheckInAt() : null,
                    logRow != null ? logRow.getCheckOutAt() : null, grace);
            rows.add(row(s.getUser(), s.getShiftDate(), schedStart, schedEnd, logRow, m));
        }
        // Unscheduled attendance (walk-in shifts) — no schedule to compare against
        for (AttendanceLog l : logs) {
            String k = key(l.getUser().getId(), l.getShiftDate());
            if (covered.contains(k)) {
                continue;
            }
            AttendanceMetrics m = metricsCalculator.derive(null, null, l.getCheckInAt(), l.getCheckOutAt(), grace);
            rows.add(row(l.getUser(), l.getShiftDate(), null, null, l, m));
        }
        return rows;
    }

    /** UC-80 — export worked hours as CSV (PDF is delivered with the P3 report exports). */
    @Transactional(readOnly = true)
    public byte[] exportWorkedHours(LocalDate from, LocalDate to, String format, UUID actorId) {
        if (format != null && !format.isBlank() && !format.equalsIgnoreCase("csv")) {
            throw AppException.of("err.065");
        }
        List<AttendanceReportRow> rows = getReport(from, to, actorId);
        StringBuilder sb = new StringBuilder();
        sb.append("employee,shiftDate,scheduledStart,scheduledEnd,checkInAt,checkOutAt,status,"
                + "lateMinutes,earlyLeaveMinutes,overtimeMinutes,workedMinutes\n");
        for (AttendanceReportRow r : rows) {
            sb.append(csv(r.employeeName())).append(',')
                    .append(r.shiftDate()).append(',')
                    .append(nullSafe(r.scheduledStart())).append(',')
                    .append(nullSafe(r.scheduledEnd())).append(',')
                    .append(nullSafe(r.checkInAt())).append(',')
                    .append(nullSafe(r.checkOutAt())).append(',')
                    .append(r.status()).append(',')
                    .append(r.lateMinutes()).append(',')
                    .append(r.earlyLeaveMinutes()).append(',')
                    .append(r.overtimeMinutes()).append(',')
                    .append(r.workedMinutes()).append('\n');
        }
        return sb.toString().getBytes(StandardCharsets.UTF_8);
    }

    /** BR-72 — null out attendance photos older than the retention window. Called by the scheduler. */
    @Transactional
    public int purgeExpiredPhotos() {
        int days = config.getGlobalInt("PHOTO_RETENTION_DAYS", 90);
        LocalDateTime cutoff = LocalDateTime.now().minusDays(days);
        List<AttendanceLog> expired = attendanceLogRepository.findByPhotoUrlIsNotNullAndCheckInAtBefore(cutoff);
        for (AttendanceLog l : expired) {
            l.setPhotoUrl(null);
            attendanceLogRepository.save(l);
        }
        if (!expired.isEmpty()) {
            log.info("[BR-72] Purged {} attendance photo(s) older than {} days", expired.size(), days);
        }
        return expired.size();
    }

    // ---- helpers ------------------------------------------------------------

    private User resolveByPin(UUID storeId, String pin) {
        LocalDateTime now = LocalDateTime.now();
        User employee = userRepository.findByStoreId(storeId).stream()
                .filter(u -> Boolean.TRUE.equals(u.getIsActive()))
                .filter(u -> pin.equals(u.getAttendancePin()))
                .findFirst()
                .orElseThrow(() -> AppException.of("err.066")); // BR-93 (PIN identifies the employee)
        if (employee.getPinLockedUntil() != null && employee.getPinLockedUntil().isAfter(now)) {
            throw AppException.of("err.067"); // BR-93 lockout
        }
        return employee;
    }

    private void clearPinLock(User employee) {
        if (nz(employee.getPinFailedAttempts()) != 0 || employee.getPinLockedUntil() != null) {
            employee.setPinFailedAttempts(0);
            employee.setPinLockedUntil(null);
            userRepository.save(employee);
        }
    }

    private AttendanceReportRow row(User user, LocalDate date, LocalDateTime schedStart, LocalDateTime schedEnd,
                                    AttendanceLog logRow, AttendanceMetrics m) {
        return new AttendanceReportRow(
                user.getId(), user.getFullName(), date, schedStart, schedEnd,
                logRow != null ? logRow.getCheckInAt() : null,
                logRow != null ? logRow.getCheckOutAt() : null,
                m.status(), m.lateMinutes(), m.earlyLeaveMinutes(), m.overtimeMinutes(), m.workedMinutes());
    }

    private static String key(UUID userId, LocalDate date) {
        return userId + "|" + date;
    }

    private static String csv(String value) {
        if (value == null) {
            return "";
        }
        return '"' + value.replace("\"", "\"\"") + '"';
    }

    private static String nullSafe(Object value) {
        return value == null ? "" : value.toString();
    }

    private static int nz(Integer v) {
        return v == null ? 0 : v;
    }

    private User currentUser(UUID actorId) {
        User user = userRepository.findById(actorId)
                .orElseThrow(() -> AppException.of("err.068"));
        if (user.getStore() == null) {
            throw AppException.of("err.069");
        }
        return user;
    }
}
