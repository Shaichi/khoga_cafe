package com.khoga.config;

import com.khoga.auth.SecurityUtil;
import com.khoga.common.dto.ApiResponse;
import com.khoga.config.dto.SystemConfigResponse;
import com.khoga.config.dto.SystemConfigUpdateRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Central (chain-wide) system settings — screen 24 / UC-24. Reading is open to HQ admins;
 * updates are SSADMIN-only and update-only (the key must already exist). Each change is audited.
 */
@RestController
@RequestMapping("/api/v1/system-config")
public class SystemConfigController {

    private final SystemConfigService systemConfigService;

    public SystemConfigController(SystemConfigService systemConfigService) {
        this.systemConfigService = systemConfigService;
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('SSADMIN','BUSINESSADMIN')")
    public ResponseEntity<ApiResponse<List<SystemConfigResponse>>> list() {
        return ResponseEntity.ok(ApiResponse.success(systemConfigService.listGlobal()));
    }

    @PutMapping("/{key}")
    @PreAuthorize("hasRole('SSADMIN')")
    public ResponseEntity<ApiResponse<SystemConfigResponse>> update(
            @PathVariable String key, @Valid @RequestBody SystemConfigUpdateRequest request) {
        SystemConfigResponse updated = systemConfigService.setGlobal(key, request.value(), SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(updated, "Cập nhật cấu hình thành công"));
    }
}
