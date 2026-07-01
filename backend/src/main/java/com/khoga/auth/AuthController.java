package com.khoga.auth;

import com.khoga.auth.dto.ChangePasswordRequest;
import com.khoga.auth.dto.ForcePasswordChangeRequest;
import com.khoga.auth.dto.ForgotPasswordRequest;
import com.khoga.auth.dto.LoginRequest;
import com.khoga.auth.dto.LoginResponse;
import com.khoga.auth.dto.MfaLoginRequest;
import com.khoga.auth.dto.ResetPasswordRequest;
import com.khoga.auth.dto.VerifyOtpRequest;
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

    /** Secure flag for the session cookie — false for local HTTP dev, true behind HTTPS (prod). */
    @org.springframework.beans.factory.annotation.Value("${app.cookie.secure:false}")
    private boolean secureCookie;

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<LoginResponse>> login(@Valid @RequestBody LoginRequest request) {
        LoginResponse response = authService.login(request);
        if (LoginResponse.MFA_REQUIRED.equals(response.status())) {
            // No token yet — the client must complete /login/mfa with the emailed OTP (BR-83).
            return ResponseEntity.ok(ApiResponse.success(response, "Vui lòng nhập mã OTP đã gửi tới email"));
        }
        return ResponseEntity.ok()
                .header(HttpHeaders.SET_COOKIE, sessionCookie(response.token(), TOKEN_TTL))
                .body(ApiResponse.success(response, "Đăng nhập thành công"));
    }

    /** BR-83 — complete an HQ login by submitting the emailed OTP. */
    @PostMapping("/login/mfa")
    public ResponseEntity<ApiResponse<LoginResponse>> loginMfa(@Valid @RequestBody MfaLoginRequest request) {
        LoginResponse response = authService.loginMfa(request);
        return ResponseEntity.ok()
                .header(HttpHeaders.SET_COOKIE, sessionCookie(response.token(), TOKEN_TTL))
                .body(ApiResponse.success(response, "Đăng nhập thành công"));
    }

    /** UC-03 — request a password-reset OTP. Always 200 (no email enumeration). */
    @PostMapping("/forgot-password")
    public ResponseEntity<ApiResponse<Void>> forgotPassword(@Valid @RequestBody ForgotPasswordRequest request) {
        authService.forgotPassword(request);
        return ResponseEntity.ok(ApiResponse.success(null,
                "Nếu email tồn tại, mã OTP đặt lại mật khẩu đã được gửi"));
    }

    /** UC-04 — verify a password-reset OTP. */
    @PostMapping("/verify-otp")
    public ResponseEntity<ApiResponse<Void>> verifyOtp(@Valid @RequestBody VerifyOtpRequest request) {
        authService.verifyOtp(request);
        return ResponseEntity.ok(ApiResponse.success(null, "Mã OTP hợp lệ"));
    }

    /** UC-05 — set a new password after a valid OTP. */
    @PostMapping("/reset-password")
    public ResponseEntity<ApiResponse<Void>> resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        authService.resetPassword(request);
        return ResponseEntity.ok(ApiResponse.success(null, "Đặt lại mật khẩu thành công"));
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
    public ResponseEntity<ApiResponse<LoginResponse>> changePassword(
            @Valid @RequestBody ChangePasswordRequest request) {
        // BR-18: the change bumps tokenVersion (revoking other sessions); refresh this client's
        // cookie with the freshly-issued token so the current session is not logged out.
        LoginResponse response = authService.changePassword(SecurityUtil.currentUserId(), request);
        return ResponseEntity.ok()
                .header(HttpHeaders.SET_COOKIE, sessionCookie(response.token(), TOKEN_TTL))
                .body(ApiResponse.success(response, "Đổi mật khẩu thành công"));
    }

    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<Void>> logout() {
        authService.logout(SecurityUtil.currentUserId());
        return ResponseEntity.ok()
                .header(HttpHeaders.SET_COOKIE, sessionCookie("", Duration.ZERO))
                .body(ApiResponse.success(null, "Đăng xuất thành công"));
    }

    /**
     * Builds the {@code Set-Cookie} value for the session token. The {@code Secure} flag is driven by
     * {@code app.cookie.secure} — false for local HTTP dev, true behind HTTPS in production.
     */
    private String sessionCookie(String token, Duration maxAge) {
        return ResponseCookie.from(TOKEN_COOKIE, token)
                .httpOnly(true)
                .secure(secureCookie)
                .sameSite("Lax")
                .path("/")
                .maxAge(maxAge)
                .build()
                .toString();
    }
}
