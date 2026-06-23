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
import org.springframework.http.ResponseCookie;
import org.springframework.http.HttpHeaders;

import java.time.Duration;

/**
 * Auth MVP endpoints (UC-01/02/06/09). {@code /login} is public; the rest require a valid token
 * (see {@code SecurityConfig}) and read the caller from the security context.
 *
 * <p>The JWT is delivered as an {@code HttpOnly} cookie ({@code khoga_token}) so browser clients
 * never touch the raw token from JavaScript (XSS hardening). {@code SameSite=Lax} mitigates CSRF.
 */
@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private static final String TOKEN_COOKIE = "khoga_token";
    private static final Duration TOKEN_TTL = Duration.ofDays(7);

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<LoginResponse>> login(@Valid @RequestBody LoginRequest request) {
        LoginResponse response = authService.login(request);
        return ResponseEntity.ok()
                .header(HttpHeaders.SET_COOKIE, sessionCookie(response.token(), TOKEN_TTL))
                .body(ApiResponse.success(response, "Đăng nhập thành công"));
    }

    @PostMapping("/force-password-change")
    public ResponseEntity<ApiResponse<LoginResponse>> forcePasswordChange(
            @Valid @RequestBody ForcePasswordChangeRequest request) {
        LoginResponse response = authService.forcePasswordChange(SecurityUtil.currentUserId(), request);
        return ResponseEntity.ok()
                .header(HttpHeaders.SET_COOKIE, sessionCookie(response.token(), TOKEN_TTL))
                .body(ApiResponse.success(response, "Đổi mật khẩu thành công"));
    }

    @PostMapping("/change-password")
    public ResponseEntity<ApiResponse<Void>> changePassword(@Valid @RequestBody ChangePasswordRequest request) {
        authService.changePassword(SecurityUtil.currentUserId(), request);
        return ResponseEntity.ok(ApiResponse.success(null, "Đổi mật khẩu thành công"));
    }

    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Void>> logout() {
        authService.logout(SecurityUtil.currentUserId());
        return ResponseEntity.ok()
                .header(HttpHeaders.SET_COOKIE, sessionCookie("", Duration.ZERO))
                .body(ApiResponse.success(null, "Đăng xuất thành công"));
    }

    /**
     * Builds the {@code Set-Cookie} value for the session token. {@code secure(false)} is for local
     * HTTP dev only — flip to {@code true} behind HTTPS in production (P4 hardening).
     */
    private static String sessionCookie(String token, Duration maxAge) {
        return ResponseCookie.from(TOKEN_COOKIE, token)
                .httpOnly(true)
                .secure(false)
                .sameSite("Lax")
                .path("/")
                .maxAge(maxAge)
                .build()
                .toString();
    }
}
