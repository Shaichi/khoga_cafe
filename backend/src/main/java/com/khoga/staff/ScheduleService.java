package com.khoga.staff;

import com.khoga.audit.AuditLogService;
import com.khoga.common.exception.AppException;
import com.khoga.common.exception.ResourceNotFoundException;
import com.khoga.common.model.StaffSchedule;
import com.khoga.common.model.Store;
import com.khoga.common.model.User;
import com.khoga.common.model.enums.ActionType;
import com.khoga.common.model.enums.Role;
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
        if (Boolean.FALSE.equals(employee.getIsActive())) {
            throw new AppException("Nhân viên đã bị vô hiệu hóa");
        }
        if (employee.getRole() == Role.CASHIER && !StringUtils.hasText(req.posRegisterId())) {
            throw new AppException("Thu ngân bắt buộc có posRegisterId"); // A46
        }
        validateConstraints(employee, store, req.shiftDate(), req.shiftStartTime(), req.shiftEndTime(),
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
            log.info("[BR-90] Cross-branch assignment: {} (home {}) → store {}",
                    employee.getUsername(), homeStoreId(employee), store.getId());
        }
        return StaffMapper.toScheduleResponse(saved, crossBranch);
    }

    /** UC-37 — edit a shift; a past shift is read-only (BR-36). Re-validates limits excluding itself. */
    @Transactional
    public ScheduleResponse update(UUID id, UpdateScheduleRequest req, UUID actorId) {
        User manager = currentUser(actorId);
        StaffSchedule schedule = loadForStore(id, manager.getStore());
        if (schedule.getShiftDate().isBefore(LocalDate.now())) {
            throw new AppException("Không thể sửa lịch trong quá khứ (BR-36)");
        }
        validateConstraints(schedule.getUser(), manager.getStore(), schedule.getShiftDate(),
                req.shiftStartTime(), req.shiftEndTime(), schedule.getId(), req.overrideReason());

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
        User employee = schedule.getUser();
        LocalDate date = schedule.getShiftDate();
        scheduleRepository.delete(schedule);
        auditLogService.record(ActionType.DELETE, "StaffSchedule", id.toString(), null, actorId);
        notifyCancellation(employee, date, schedule); // BR-37
    }

    // ---- validation ---------------------------------------------------------

    private void validateConstraints(User employee, Store store, LocalDate date, LocalTime start,
                                     LocalTime end, UUID excludeId, String overrideReason) {
        long shiftMinutes = shiftMinutes(start, end);

        // BR-92 hard: per-day total hours
        long maxDaily = config.getGlobalInt("STAFF_MAX_DAILY_HOURS", 12) * 60L;
        long dailyExisting = sumMinutes(scheduleRepository.findByUserIdAndShiftDate(employee.getId(), date), excludeId);
        if (dailyExisting + shiftMinutes > maxDaily) {
            throw new AppException("Vượt số giờ tối đa trong ngày (BR-92)");
        }

        // BR-92 hard: per-week total hours
        LocalDate weekStart = date.with(DayOfWeek.MONDAY);
        LocalDate weekEnd = weekStart.plusDays(6);
        long maxWeekly = config.getGlobalInt("STAFF_MAX_WEEKLY_HOURS", 48) * 60L;
        long weeklyExisting = sumMinutes(
                scheduleRepository.findByUserIdAndShiftDateBetween(employee.getId(), weekStart, weekEnd), excludeId);
        if (weeklyExisting + shiftMinutes > maxWeekly) {
            throw new AppException("Vượt số giờ tối đa trong tuần (BR-92)");
        }

        // BR-92 hard: conflict (overlap) + minimum rest between shifts
        long minRestMinutes = config.getGlobalInt("STAFF_MIN_REST_HOURS", 8) * 60L;
        LocalDateTime newStart = LocalDateTime.of(date, start);
        LocalDateTime newEnd = LocalDateTime.of(date, end);
        for (StaffSchedule other : scheduleRepository.findByUserIdAndShiftDateBetween(
                employee.getId(), date.minusDays(1), date.plusDays(1))) {
            if (excludeId != null && excludeId.equals(other.getId())) {
                continue;
            }
            LocalDateTime oStart = LocalDateTime.of(other.getShiftDate(), other.getShiftStartTime());
            LocalDateTime oEnd = LocalDateTime.of(other.getShiftDate(), other.getShiftEndTime());
            if (newStart.isBefore(oEnd) && oStart.isBefore(newEnd)) {
                throw new AppException("Nhân viên đã có ca trùng giờ (BR-92)");
            }
            long gap = oEnd.isBefore(newStart) || oEnd.isEqual(newStart)
                    ? Duration.between(oEnd, newStart).toMinutes()
                    : Duration.between(newEnd, oStart).toMinutes();
            if (gap < minRestMinutes) {
                throw new AppException("Không đủ thời gian nghỉ tối thiểu giữa các ca (BR-92)");
            }
        }

        // BR-92 soft: per-day labour budget for the whole branch — overridable with a reason
        long budget = config.getGlobalInt("STORE_DAILY_LABOUR_BUDGET_HOURS", 40) * 60L;
        long storeExisting = sumMinutes(scheduleRepository.findByStoreIdAndShiftDate(store.getId(), date), excludeId);
        if (storeExisting + shiftMinutes > budget && !StringUtils.hasText(overrideReason)) {
            throw new AppException("Vượt ngân sách giờ công của ngày — cần nhập lý do override (BR-92)");
        }
        if (storeExisting + shiftMinutes > budget) {
            auditLogService.record(ActionType.UPDATE, "LabourBudgetOverride", null,
                    "{\"store\":\"" + store.getId() + "\",\"date\":\"" + date + "\",\"reason\":\""
                            + overrideReason + "\"}", null);
            log.info("[BR-92] Labour budget override at store {} on {} — {}", store.getId(), date, overrideReason);
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

    private static long shiftMinutes(LocalTime start, LocalTime end) {
        long minutes = Duration.between(start, end).toMinutes();
        if (minutes <= 0) {
            throw new AppException("Giờ kết thúc phải sau giờ bắt đầu");
        }
        return minutes;
    }

    private StaffSchedule loadForStore(UUID id, Store store) {
        StaffSchedule schedule = scheduleRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy lịch làm việc"));
        if (schedule.getStore() == null || !schedule.getStore().getId().equals(store.getId())) {
            throw new AppException("Lịch không thuộc chi nhánh của bạn"); // BR-59
        }
        return schedule;
    }

    private User currentUser(UUID actorId) {
        User user = userRepository.findById(actorId)
                .orElseThrow(() -> new AppException("Yêu cầu xác thực"));
        if (user.getStore() == null) {
            throw new AppException("Tài khoản không gắn với chi nhánh nào");
        }
        return user;
    }
}
