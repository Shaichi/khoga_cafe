package com.khoga.user;

import com.khoga.auth.SecurityUtil;
import com.khoga.common.dto.ApiResponse;
import com.khoga.common.dto.PageResponse;
import com.khoga.common.model.enums.Role;
import com.khoga.user.dto.CreateUserRequest;
import com.khoga.user.dto.UpdateUserRequest;
import com.khoga.user.dto.UserDetailResponse;
import com.khoga.user.dto.UserResponse;
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

/** Employee account administration (UC-10/11/12/13/14). HQ-only (SSADMIN). */
@RestController
@RequestMapping("/api/v1/users")
@PreAuthorize("hasRole('SSADMIN')")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<UserResponse>>> list(
            @RequestParam(required = false) Role role,
            @RequestParam(required = false) String search,
            @PageableDefault(size = 20) Pageable pageable) {
        Page<UserResponse> page = userService.list(role, search, pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.of(page)));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<UserDetailResponse>> get(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.success(userService.get(id)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<UserResponse>> create(@Valid @RequestBody CreateUserRequest request) {
        UserResponse created = userService.create(request, SecurityUtil.currentUserId());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(created, "Tạo người dùng thành công"));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<UserResponse>> update(
            @PathVariable UUID id, @Valid @RequestBody UpdateUserRequest request) {
        UserResponse updated = userService.update(id, request, SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(updated, "Cập nhật người dùng thành công"));
    }

    @PostMapping("/{id}/deactivate")
    public ResponseEntity<ApiResponse<UserResponse>> deactivate(@PathVariable UUID id) {
        UserResponse updated = userService.setActive(id, false, SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(updated, "Đã vô hiệu hóa người dùng"));
    }

    @PostMapping("/{id}/activate")
    public ResponseEntity<ApiResponse<UserResponse>> activate(@PathVariable UUID id) {
        UserResponse updated = userService.setActive(id, true, SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(updated, "Đã kích hoạt người dùng"));
    }
}
