package com.khoga.staff;

import com.khoga.audit.AuditJson;
import com.khoga.audit.AuditLogService;
import com.khoga.common.exception.AppException;
import com.khoga.common.exception.ResourceNotFoundException;
import com.khoga.common.model.StaffSchedule;
import com.khoga.common.model.Store;
import com.khoga.common.model.User;
import com.khoga.common.model.enums.ActionType;
import com.khoga.common.model.enums.Role;
import com.khoga.common.model.enums.ShiftType;
import com.khoga.common.repository.StaffScheduleRepository;
import com.khoga.common.repository.UserRepository;
import com.khoga.config.SystemConfigService;
import com.khoga.integration.EmailService;
import com.khoga.staff.dto.CreateScheduleRequest;
import com.khoga.staff.dto.ScheduleResponse;
import com.khoga.staff.dto.StaffRosterResponse;
import com.khoga.staff.dto.UpdateScheduleRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.DayOfWeek;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

/**
 * Staff scheduling (UC-35/36/37/38) and the branch roster (UC-66). Store-Manager scope only (BR-59):
 * the manager schedules into their own branch; a cross-branch employee is assigned directly without
 * host approval (BR-90) and audited. Creation enforces the hard time limits MAX_DAILY/WEEKLY_HOURS and
 * MIN_REST_HOURS plus a same-employee conflict check (BR-92); the per-day labour budget is a soft cap
 * that an explicit reason can override (BR-92). Past shifts are read-only (BR-36); deletion notifies the
 * affected employee (BR-37).
 */
@Slf4j
@Service
public class ScheduleService {

    private final StaffScheduleRepository scheduleRepository;
    private final UserRepository userRepository;
    private final SystemConfigService config;
    private final AuditLogService auditLogService;
    private final EmailService emailService;

    public ScheduleService(StaffScheduleRepository scheduleRepository, UserRepository userRepository,
                           SystemConfigService config, AuditLogService auditLogService,
                           EmailService emailService) {
        this.scheduleRepository = scheduleRepository;
        this.userRepository = userRepository;
        this.config = config;
        this.auditLogService = auditLogService;
        this.emailService = emailService;
    }

    /** UC-35 — branch schedule calendar over a date window (default: current week if both null). */
    @Transactional(readOnly = true)
    public List<ScheduleResponse> getSchedule(LocalDate from, LocalDate to, UUID actorId) {
        UUID storeId = currentUser(actorId).getStore().getId();
        LocalDate start = from != null ? from : LocalDate.now().with(DayOfWeek.MONDAY);
        LocalDate end = to != null ? to : start.plusDays(6);
        return scheduleRepository.findByStoreIdAndShiftDateBetween(storeId, start, end).stream()
                .map(s -> StaffMapper.toScheduleResponse(s, isCrossBranch(s.getUser(), storeId)))
                .toList();
    }

    /** UC-66 — roster of staff at the manager's branch. */
    @Transactional(readOnly = true)
    public List<StaffRosterResponse> getBranchStaff(UUID actorId) {
        UUID storeId = currentUser(actorId).getStore().getId();
        LocalDateTime now = LocalDateTime.now();
        return userRepository.findByStoreId(storeId).stream()
                .map(u -> StaffMapper.toRoster(u, u.getPinLockedUntil() != null && u.getPinLockedUntil().isAfter(now)))
                .toList();
    }

    /** UC-36 — create a shift with BR-92 hard limits + conflict check and the soft labour-budget gate. */
    @Transactional
    public ScheduleResponse create(CreateScheduleRequest req, UUID actorId) {
        User manager = currentUser(actorId);
        Store store = manager.getStore();
        User employee = userRepository.findById(req.employeeId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy nhân viên"));
        if (req.shiftDate().isBefore(LocalDate.now())) {
            throw new AppException("Không thể thêm ca làm việc trong quá khứ");
        }
        if (Boolean.FALSE.equals(employee.getIsActive())) {
            throw AppException.of("err.070");
        }
        if (employee.getRole() == Role.CASHIER && !StringUtils.hasText(req.posRegisterId())) {
            throw AppException.of("err.071"); // A46
        }
        validateConstraints(employee, store, req.shiftDate(), req.shiftType(), req.shiftStartTime(), req.shiftEndTime(),
                null, req.overrideReason());

        boolean crossBranch = isCrossBranch(employee, store.getId());
        StaffSchedule schedule = new StaffSchedule();
        schedule.setStore(store);
        schedule.setUser(employee);
        schedule.setShiftDate(req.shiftDate());
        schedule.setShiftType(req.shiftType());
        schedule.setShiftStartTime(req.shiftStartTime());
        schedule.setShiftEndTime(req.shiftEndTime());
        schedule.setPosRegisterId(req.posRegisterId());
        StaffSchedule saved = scheduleRepository.save(schedule);

        auditLogService.record(ActionType.CREATE, "StaffSchedule", null,
                "{\"employee\":\"" + employee.getUsername() + "\",\"date\":\"" + req.shiftDate()
                        + "\",\"crossBranch\":" + crossBranch + "}", actorId);
        if (crossBranch) {
            // BR-90 / RDS §3.9 logCrossBranchAssignment — a dedicated audit row (not just a flag on the
            // CREATE above) recording employee, home store, target store and the authorising manager.
            UUID home = homeStoreId(employee);
            auditLogService.record(ActionType.CREATE, "StaffScheduleCrossBranch", null,
                    AuditJson.snapshot()
                            .put("employeeId", employee.getId() == null ? null : employee.getId().toString())
                            .put("homeStoreId", home == null ? null : home.toString())
                            .put("targetStoreId", store.getId().toString())
                            .put("managerId", actorId == null ? null : actorId.toString())
                            .json(), actorId);
            log.info("[BR-90] Cross-branch assignment: {} (home {}) → store {}",
                    employee.getUsername(), home, store.getId());
        }
        return StaffMapper.toScheduleResponse(saved, crossBranch);
    }

    /** UC-37 — edit a shift; a past shift is read-only (BR-36). Re-validates limits excluding itself. */
    @Transactional
    public ScheduleResponse update(UUID id, UpdateScheduleRequest req, UUID actorId) {
        User manager = currentUser(actorId);
        StaffSchedule schedule = loadForStore(id, manager.getStore());
        if (schedule.getShiftDate().isBefore(LocalDate.now())) {
            throw new AppException("Không thể sửa ca làm việc trong quá khứ");
        }
        validateConstraints(schedule.getUser(), manager.getStore(), schedule.getShiftDate(),
                req.shiftType(), req.shiftStartTime(), req.shiftEndTime(), schedule.getId(), req.overrideReason());

        schedule.setShiftType(req.shiftType());
        schedule.setShiftStartTime(req.shiftStartTime());
        schedule.setShiftEndTime(req.shiftEndTime());
        schedule.setPosRegisterId(req.posRegisterId());
        StaffSchedule saved = scheduleRepository.save(schedule);
        auditLogService.record(ActionType.UPDATE, "StaffSchedule", null, id.toString(), actorId);
        return StaffMapper.toScheduleResponse(saved, isCrossBranch(saved.getUser(), manager.getStore().getId()));
    }

    /** UC-38 — delete a shift and notify the affected employee (BR-37). */
    @Transactional
    public void delete(UUID id, UUID actorId) {
        User manager = currentUser(actorId);
        StaffSchedule schedule = loadForStore(id, manager.getStore());
        if (schedule.getShiftDate().isBefore(LocalDate.now())) {
            throw new AppException("Không thể xóa ca làm việc trong quá khứ");
        }
        User employee = schedule.getUser();
        LocalDate date = schedule.getShiftDate();
        scheduleRepository.delete(schedule);
        auditLogService.record(ActionType.DELETE, "StaffSchedule", id.toString(), null, actorId);
        notifyCancellation(employee, date, schedule); // BR-37
    }

    // ---- validation ---------------------------------------------------------

    private void validateConstraints(User employee, Store store, LocalDate date, ShiftType shiftType, LocalTime start,
                                     LocalTime end, UUID excludeId, String overrideReason) {
        // Duplicate shift check
        for (StaffSchedule existing : scheduleRepository.findByUserIdAndShiftDate(employee.getId(), date)) {
            if (excludeId != null && excludeId.equals(existing.getId())) {
                continue;
            }
            throw new AppException("Nhân viên này đã được phân ca " + existing.getShiftType() + " trong ngày " + date + ". Không thể phân thêm ca khác.");
        }
    }

    private void notifyCancellation(User employee, LocalDate date, StaffSchedule schedule) {
        if (employee == null || employee.getEmail() == null || employee.getEmail().isBlank()) {
            return;
        }
        emailService.send(employee.getEmail(), "[BR-37] Ca làm việc đã bị hủy",
                "Ca " + schedule.getShiftType() + " ngày " + date + " của bạn đã bị hủy. Vui lòng xem lịch mới.");
    }

    private boolean isCrossBranch(User employee, UUID storeId) {
        UUID home = homeStoreId(employee);
        return home == null || !home.equals(storeId);
    }

    private static UUID homeStoreId(User employee) {
        return employee != null && employee.getStore() != null ? employee.getStore().getId() : null;
    }

    private static long sumMinutes(List<StaffSchedule> schedules, UUID excludeId) {
        long total = 0;
        for (StaffSchedule s : schedules) {
            if (excludeId != null && excludeId.equals(s.getId())) {
                continue;
            }
            total += Math.max(0, Duration.between(s.getShiftStartTime(), s.getShiftEndTime()).toMinutes());
        }
        return total;
    }

    private StaffSchedule loadForStore(UUID id, Store store) {
        StaffSchedule schedule = scheduleRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy lịch làm việc"));
        if (schedule.getStore() == null || !schedule.getStore().getId().equals(store.getId())) {
            throw AppException.of("err.078"); // BR-59
        }
        return schedule;
    }

    private User currentUser(UUID actorId) {
        User user = userRepository.findById(actorId)
                .orElseThrow(() -> AppException.of("err.079"));
        if (user.getStore() == null) {
            throw AppException.of("err.080");
        }
        return user;
    }
}
