package com.khoga.staff;

import com.khoga.auth.SecurityUtil;
import com.khoga.common.dto.ApiResponse;
import com.khoga.staff.dto.CreateScheduleRequest;
import com.khoga.staff.dto.ScheduleResponse;
import com.khoga.staff.dto.StaffRosterResponse;
import com.khoga.staff.dto.UpdateScheduleRequest;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/** Staff scheduling + roster (UC-35/36/37/38/66). Store Manager scope only (BR-59). */
@RestController
@RequestMapping("/api/v1")
@PreAuthorize("hasRole('STORE_MANAGER')")
public class ScheduleController {

    private final ScheduleService scheduleService;

    public ScheduleController(ScheduleService scheduleService) {
        this.scheduleService = scheduleService;
    }

    /** UC-35 — schedule calendar (defaults to the current week when no range is given). */
    @GetMapping("/schedules")
    public ResponseEntity<ApiResponse<List<ScheduleResponse>>> list(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ResponseEntity.ok(ApiResponse.success(
                scheduleService.getSchedule(from, to, SecurityUtil.currentUserId())));
    }

    /** UC-66 — branch staff roster. */
    @GetMapping("/staff")
    public ResponseEntity<ApiResponse<List<StaffRosterResponse>>> roster() {
        return ResponseEntity.ok(ApiResponse.success(
                scheduleService.getBranchStaff(SecurityUtil.currentUserId())));
    }

    /** UC-36 — create a shift. */
    @PostMapping("/schedules")
    public ResponseEntity<ApiResponse<ScheduleResponse>> create(@Valid @RequestBody CreateScheduleRequest req) {
        ScheduleResponse res = scheduleService.create(req, SecurityUtil.currentUserId());
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(res, "Đã tạo lịch làm việc"));
    }

    /** UC-37 — edit a shift (past shifts are read-only, BR-36). */
    @PutMapping("/schedules/{id}")
    public ResponseEntity<ApiResponse<ScheduleResponse>> update(
            @PathVariable UUID id, @Valid @RequestBody UpdateScheduleRequest req) {
        ScheduleResponse res = scheduleService.update(id, req, SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(res, "Đã cập nhật lịch"));
    }

    /** UC-38 — delete a shift (notifies the affected employee, BR-37). */
    @DeleteMapping("/schedules/{id}")
    public ResponseEntity<ApiResponse<Void>> delete(@PathVariable UUID id) {
        scheduleService.delete(id, SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(null, "Đã xóa lịch"));
    }
}
