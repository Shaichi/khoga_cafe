package com.khoga.voucher;

import com.khoga.auth.SecurityUtil;
import com.khoga.common.dto.ApiResponse;
import com.khoga.common.dto.PageResponse;
import com.khoga.voucher.dto.CreateVoucherRequest;
import com.khoga.voucher.dto.UpdateVoucherRequest;
import com.khoga.voucher.dto.VoucherResponse;
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
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

/** Voucher management (UC-20/21/22/23). Reads open to authenticated staff; mutations HQ-only. */
@RestController
@RequestMapping("/api/v1/vouchers")
public class VoucherController {

    private final VoucherService voucherService;

    public VoucherController(VoucherService voucherService) {
        this.voucherService = voucherService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<VoucherResponse>>> list(
            @PageableDefault(size = 20) Pageable pageable) {
        Page<VoucherResponse> page = voucherService.list(pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.of(page)));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<VoucherResponse>> get(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.success(voucherService.get(id)));
    }

    @PostMapping
    @PreAuthorize("hasRole('SSADMIN')")
    public ResponseEntity<ApiResponse<VoucherResponse>> create(@Valid @RequestBody CreateVoucherRequest request) {
        VoucherResponse created = voucherService.create(request, SecurityUtil.currentUserId());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(created, "Tạo voucher thành công"));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('SSADMIN')")
    public ResponseEntity<ApiResponse<VoucherResponse>> update(
            @PathVariable UUID id, @Valid @RequestBody UpdateVoucherRequest request) {
        VoucherResponse updated = voucherService.update(id, request, SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(updated, "Cập nhật voucher thành công"));
    }

    @PostMapping("/{id}/deactivate")
    @PreAuthorize("hasRole('SSADMIN')")
    public ResponseEntity<ApiResponse<Void>> deactivate(@PathVariable UUID id) {
        voucherService.deactivate(id, SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(null, "Đã vô hiệu hóa voucher"));
    }
}
