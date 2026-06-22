package com.khoga.auth;

import com.khoga.auth.dto.ChangePasswordRequest;
import com.khoga.auth.dto.ForcePasswordChangeRequest;
import com.khoga.auth.dto.LoginRequest;
import com.khoga.auth.dto.LoginResponse;
import com.khoga.common.dto.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Auth MVP endpoints (UC-01/02/06/09). {@code /login} is public; the rest require a valid token
 * (see {@code SecurityConfig}) and read the caller from the security context.
 */
@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<LoginResponse>> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(ApiResponse.success(authService.login(request), "Đăng nhập thành công"));
    }

    @PostMapping("/force-password-change")
    public ResponseEntity<ApiResponse<LoginResponse>> forcePasswordChange(
            @Valid @RequestBody ForcePasswordChangeRequest request) {
        LoginResponse response = authService.forcePasswordChange(SecurityUtil.currentUserId(), request);
        return ResponseEntity.ok(ApiResponse.success(response, "Đổi mật khẩu thành công"));
    }

    @PostMapping("/change-password")
    public ResponseEntity<ApiResponse<Void>> changePassword(@Valid @RequestBody ChangePasswordRequest request) {
        authService.changePassword(SecurityUtil.currentUserId(), request);
        return ResponseEntity.ok(ApiResponse.success(null, "Đổi mật khẩu thành công"));
    }

    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Void>> logout() {
        authService.logout(SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(null, "Đăng xuất thành công"));
    }
}
