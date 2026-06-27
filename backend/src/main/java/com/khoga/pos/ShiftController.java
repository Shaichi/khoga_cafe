package com.khoga.pos;

import com.khoga.auth.SecurityUtil;
import com.khoga.common.dto.ApiResponse;
import com.khoga.pos.dto.CloseShiftRequest;
import com.khoga.pos.dto.OpenShiftRequest;
import com.khoga.pos.dto.ShiftResponse;
import com.khoga.pos.dto.ZReportResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

/** Shift session control (UC-44 open, UC-53 close). Cashier operates; Store Manager may override. */
@RestController
@RequestMapping("/api/v1/shifts")
@PreAuthorize("hasAnyRole('CASHIER','STORE_MANAGER')")
public class ShiftController {

    private final ShiftService shiftService;

    public ShiftController(ShiftService shiftService) {
        this.shiftService = shiftService;
    }

    @PostMapping("/open")
    public ResponseEntity<ApiResponse<ShiftResponse>> open(@Valid @RequestBody OpenShiftRequest req) {
        ShiftResponse res = shiftService.openShift(req, SecurityUtil.currentUserId());
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(res, "Đã mở ca"));
    }

    @GetMapping("/active")
    public ResponseEntity<ApiResponse<ShiftResponse>> active() {
        return ResponseEntity.ok(ApiResponse.success(shiftService.getActiveShift(SecurityUtil.currentUserId())));
    }

    @PostMapping("/{id}/close")
    public ResponseEntity<ApiResponse<ZReportResponse>> close(
            @PathVariable UUID id, @Valid @RequestBody CloseShiftRequest req) {
        ZReportResponse z = shiftService.closeShift(id, req.closingCash(), SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(z, "Đã đóng ca"));
    }
}
