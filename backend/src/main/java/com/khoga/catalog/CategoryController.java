package com.khoga.catalog;

import com.khoga.auth.SecurityUtil;
import com.khoga.catalog.dto.CategoryRequest;
import com.khoga.catalog.dto.CategoryResponse;
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

@RestController
@RequestMapping("/api/v1/categories")
public class CategoryController {

    private final CategoryService categoryService;

    public CategoryController(CategoryService categoryService) {
        this.categoryService = categoryService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<CategoryResponse>>> list(
            @RequestParam(required = false) Boolean active,
            @PageableDefault(size = 20) Pageable pageable) {
        Page<CategoryResponse> page = categoryService.list(active, pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.of(page)));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('BUSINESSADMIN','SSADMIN')")
    public ResponseEntity<ApiResponse<CategoryResponse>> create(@Valid @RequestBody CategoryRequest request) {
        CategoryResponse created = categoryService.create(request, SecurityUtil.currentUserId());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(created, "Tạo danh mục thành công"));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('BUSINESSADMIN','SSADMIN')")
    public ResponseEntity<ApiResponse<CategoryResponse>> update(
            @PathVariable UUID id, @Valid @RequestBody CategoryRequest request) {
        CategoryResponse updated = categoryService.update(id, request, SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(updated, "Cập nhật danh mục thành công"));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('BUSINESSADMIN','SSADMIN')")
    public ResponseEntity<ApiResponse<Void>> archive(@PathVariable UUID id) {
        categoryService.archive(id, SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(null, "Đã lưu trữ danh mục"));
    }
}
