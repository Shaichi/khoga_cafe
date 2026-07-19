package com.khoga.staff;

import com.khoga.auth.SecurityUtil;
import com.khoga.common.dto.ApiResponse;
import com.khoga.staff.dto.AttendanceReportRow;
import com.khoga.staff.dto.AttendanceResponse;
import com.khoga.staff.dto.CheckInRequest;
import com.khoga.staff.dto.CheckOutRequest;
import com.khoga.staff.dto.VerifyAttendanceRequest;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Attendance (UC-67/39/80). Check-in/out is operated at a branch terminal by any branch staff and
 * identifies the employee by PIN; report/verify/export are Store-Manager-only (BR-59).
 */
@RestController
@RequestMapping("/api/v1/attendance")
public class AttendanceController {

    private final AttendanceService attendanceService;

    public AttendanceController(AttendanceService attendanceService) {
        this.attendanceService = attendanceService;
    }

    /** UC-67 — check-in with PIN + photo. */
    @PostMapping("/check-in")
    @PreAuthorize("hasAnyRole('CASHIER','BARISTA','STORE_MANAGER')")
    public ResponseEntity<ApiResponse<AttendanceResponse>> checkIn(@Valid @RequestBody CheckInRequest req) {
        AttendanceResponse res = attendanceService.checkIn(req, SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(res, "Đã check-in"));
    }

    /** UC-67 — check-out (closes the open pairing). */
    @PostMapping("/check-out")
    @PreAuthorize("hasAnyRole('CASHIER','BARISTA','STORE_MANAGER')")
    public ResponseEntity<ApiResponse<AttendanceResponse>> checkOut(@Valid @RequestBody CheckOutRequest req) {
        AttendanceResponse res = attendanceService.checkOut(req, SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(res, "Đã check-out"));
    }

    /** SM confirms a photoless check-in (BR-93 fallback). */
    @PostMapping("/{id}/verify")
    @PreAuthorize("hasRole('STORE_MANAGER')")
    public ResponseEntity<ApiResponse<AttendanceResponse>> verify(
            @PathVariable UUID id, @RequestBody(required = false) VerifyAttendanceRequest req) {
        AttendanceResponse res = attendanceService.verifyPending(id, req, SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(res, "Đã xác nhận chấm công"));
    }

    /** Manager manually updates attendance for today. */
    @org.springframework.web.bind.annotation.PutMapping("/manual")
    @PreAuthorize("hasRole('STORE_MANAGER')")
    public ResponseEntity<ApiResponse<AttendanceResponse>> manualUpdate(
            @RequestBody com.khoga.staff.dto.ManualAttendanceRequest req) {
        AttendanceResponse res = attendanceService.manualUpdate(req, SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(res, "Đã cập nhật điểm danh"));
    }

    /** UC-39 — attendance report with derived metrics (BR-91). */
    @GetMapping
    @PreAuthorize("hasRole('STORE_MANAGER')")
    public ResponseEntity<ApiResponse<List<AttendanceReportRow>>> report(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ResponseEntity.ok(ApiResponse.success(
                attendanceService.getReport(from, to, SecurityUtil.currentUserId())));
    }

    /** UC-80 — export worked hours as CSV (BR-77). */
    @GetMapping("/export")
    @PreAuthorize("hasRole('STORE_MANAGER')")
    public ResponseEntity<byte[]> export(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(required = false, defaultValue = "csv") String format) {
        byte[] body = attendanceService.exportWorkedHours(from, to, format, SecurityUtil.currentUserId());
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"worked-hours.csv\"")
                .contentType(MediaType.parseMediaType("text/csv"))
                .body(body);
    }
}
