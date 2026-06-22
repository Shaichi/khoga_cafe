package com.khoga.catalog;

import com.khoga.auth.SecurityUtil;
import com.khoga.catalog.dto.CreateRawMaterialRequest;
import com.khoga.catalog.dto.RawMaterialResponse;
import com.khoga.catalog.dto.UpdateRawMaterialRequest;
import com.khoga.common.dto.ApiResponse;
import com.khoga.common.dto.PageResponse;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
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

import java.util.UUID;

/** Raw-material master administration (UC-74). HQ-only (businessadmin ≡ SSADMIN here). */
@RestController
@RequestMapping("/api/v1/raw-materials")
@PreAuthorize("hasRole('SSADMIN')")
public class RawMaterialController {

    private final RawMaterialService rawMaterialService;

    public RawMaterialController(RawMaterialService rawMaterialService) {
        this.rawMaterialService = rawMaterialService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<RawMaterialResponse>>> list(
            @RequestParam(required = false) Boolean active,
            @RequestParam(required = false) String search,
            @PageableDefault(size = 20) Pageable pageable) {
        Page<RawMaterialResponse> page = rawMaterialService.list(active, search, pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.of(page)));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<RawMaterialResponse>> get(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.success(rawMaterialService.get(id)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<RawMaterialResponse>> create(
            @Valid @RequestBody CreateRawMaterialRequest request) {
        RawMaterialResponse created = rawMaterialService.create(request, SecurityUtil.currentUserId());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(created, "Tạo nguyên liệu thành công"));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<RawMaterialResponse>> update(
            @PathVariable UUID id, @Valid @RequestBody UpdateRawMaterialRequest request) {
        RawMaterialResponse updated = rawMaterialService.update(id, request, SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(updated, "Cập nhật nguyên liệu thành công"));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deactivate(@PathVariable UUID id) {
        rawMaterialService.deactivate(id, SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(null, "Đã ngừng sử dụng nguyên liệu"));
    }
}
