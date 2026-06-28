package com.khoga.branch;

import com.khoga.auth.SecurityUtil;
import com.khoga.branch.dto.BranchResponse;
import com.khoga.branch.dto.BranchSettingsRequest;
import com.khoga.branch.dto.BranchSettingsResponse;
import com.khoga.branch.dto.CreateBranchRequest;
import com.khoga.branch.dto.UpdateBranchRequest;
import com.khoga.common.dto.ApiResponse;
import com.khoga.common.dto.PageResponse;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

/**
 * Branch master-data endpoints (UC-63/64/65/42). Read is open to any authenticated staff; mutations
 * are HQ-only (SSADMIN); branch settings additionally allow a store manager (scoped in the service).
 */
@RestController
@RequestMapping("/api/v1/branches")
public class BranchController {

    private final BranchService branchService;

    public BranchController(BranchService branchService) {
        this.branchService = branchService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<BranchResponse>>> list(
            @RequestParam(required = false) Boolean active,
            @PageableDefault(size = 20) Pageable pageable) {
        Page<BranchResponse> page = branchService.list(active, pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.of(page)));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<BranchResponse>> get(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.success(branchService.get(id)));
    }

    @PostMapping
    @PreAuthorize("hasRole('SSADMIN')")
    public ResponseEntity<ApiResponse<BranchResponse>> create(@Valid @RequestBody CreateBranchRequest request) {
        BranchResponse created = branchService.create(request, SecurityUtil.currentUserId());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(created, "Tạo chi nhánh thành công"));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('SSADMIN')")
    public ResponseEntity<ApiResponse<BranchResponse>> update(
            @PathVariable UUID id, @Valid @RequestBody UpdateBranchRequest request) {
        BranchResponse updated = branchService.update(id, request, SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(updated, "Cập nhật chi nhánh thành công"));
    }

    @PostMapping("/{id}/deactivate")
    @PreAuthorize("hasRole('SSADMIN')")
    public ResponseEntity<ApiResponse<Void>> deactivate(@PathVariable UUID id) {
        branchService.deactivate(id, SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(null, "Đã vô hiệu hóa chi nhánh"));
    }

    @GetMapping("/{id}/settings")
    @PreAuthorize("hasAnyRole('SSADMIN','STORE_MANAGER')")
    public ResponseEntity<ApiResponse<BranchSettingsResponse>> getSettings(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.success(branchService.getSettings(id, SecurityUtil.currentUserId())));
    }

    @PutMapping("/{id}/settings")
    @PreAuthorize("hasAnyRole('SSADMIN','STORE_MANAGER')")
    public ResponseEntity<ApiResponse<BranchResponse>> updateSettings(
            @PathVariable UUID id, @Valid @RequestBody BranchSettingsRequest request) {
        BranchResponse updated = branchService.updateSettings(id, request, SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(updated, "Cập nhật cấu hình chi nhánh thành công"));
    }
}
