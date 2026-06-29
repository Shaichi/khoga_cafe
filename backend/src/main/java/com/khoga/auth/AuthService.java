package com.khoga.auth;

import com.khoga.audit.AuditLogService;
import com.khoga.auth.dto.ChangePasswordRequest;
import com.khoga.auth.dto.ForcePasswordChangeRequest;
import com.khoga.auth.dto.ForgotPasswordRequest;
import com.khoga.auth.dto.LoginRequest;
import com.khoga.auth.dto.LoginResponse;
import com.khoga.auth.dto.MfaLoginRequest;
import com.khoga.auth.dto.ResetPasswordRequest;
import com.khoga.auth.dto.VerifyOtpRequest;
import com.khoga.common.exception.AppException;
import com.khoga.common.exception.ResourceNotFoundException;
import com.khoga.common.model.User;
import com.khoga.common.model.enums.ActionType;
import com.khoga.common.model.enums.Role;
import com.khoga.common.repository.UserRepository;
import com.khoga.config.SystemConfigService;
import com.khoga.integration.EmailService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.EnumSet;
import java.util.Set;
import java.util.UUID;

/**
 * Authentication coordinator for the Auth MVP (UC-01/02/06/09). Stateless JWT: a successful login
 * issues a token the client holds; logout is client-side (BR-13/BR-60). Lockout follows BR-11.
 *
 * <p><b>Known MVP limitation (deferred to P1B):</b> a user with {@code mustChangePassword=true}
 * still receives a fully usable token — {@code LoginResponse.mustChangePassword} signals the client
 * to redirect to the change-password screen, but the server does not yet block that user from other
 * authenticated endpoints. Enforcing UC-06's "must change before proceeding" server-side needs a
 * {@code mustChangePassword} JWT claim + a gate filter; that lands with the P1B auth hardening.
 */
@Service
public class AuthService {

    /** BR-11: lock the account after this many consecutive failures. */
    static final int MAX_FAILED_ATTEMPTS = 5;
    /** BR-11: how long the lock lasts. */
    static final int LOCK_MINUTES = 15;
    /** BR-83: roles that must clear a second factor at login when HQ_MFA_REQUIRED is on. */
    private static final Set<Role> HQ_ROLES = EnumSet.of(Role.CEOVIEWER, Role.BUSINESSADMIN, Role.SSADMIN);

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider tokenProvider;
    private final AuditLogService auditLogService;
    private final OtpStore otpStore;
    private final EmailService emailService;
    private final SystemConfigService systemConfig;

    public AuthService(UserRepository userRepository, PasswordEncoder passwordEncoder,
                       JwtTokenProvider tokenProvider, AuditLogService auditLogService,
                       OtpStore otpStore, EmailService emailService, SystemConfigService systemConfig) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.tokenProvider = tokenProvider;
        this.auditLogService = auditLogService;
        this.otpStore = otpStore;
        this.emailService = emailService;
        this.systemConfig = systemConfig;
    }

    /** UC-01: verify credentials, enforce active/lock state (BR-10/BR-11), and issue a JWT. */
    @Transactional
    public LoginResponse login(LoginRequest request) {
        User user = userRepository.findByUsername(request.username())
                .orElseThrow(() -> new AppException("Tên đăng nhập hoặc mật khẩu không đúng"));

        if (Boolean.FALSE.equals(user.getIsActive())) {
            throw new AppException("Tài khoản đã bị vô hiệu hóa");            // BR-10
        }
        if (isLocked(user)) {
            throw new AppException("Tài khoản đang bị khóa, vui lòng thử lại sau");  // BR-11
        }
        clearExpiredLock(user);
        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            registerFailure(user);
            throw new AppException("Tên đăng nhập hoặc mật khẩu không đúng");
        }

        // Password is correct — clear the lockout counter.
        user.setFailedAttempts(0);
        user.setLockExpiryAt(null);

        // BR-83: HQ roles need a second factor before a token is issued.
        if (needsMfa(user)) {
            userRepository.save(user);
            return startMfaChallenge(user);
        }

        user.setLastLoginAt(LocalDateTime.now());
        userRepository.save(user);
        return issueToken(user);
    }

    /**
     * BR-83 step 2 — complete an HQ login by submitting the emailed OTP. On success issues the JWT;
     * a wrong/expired/locked challenge throws (the OTP enforces the 3-try limit, BR-17).
     */
    @Transactional
    public LoginResponse loginMfa(MfaLoginRequest request) {
        requireOtp(otpStore.verify(request.mfaToken(), request.otp()));
        UUID userId = otpStore.consume(request.mfaToken());
        if (userId == null) {
            throw new AppException("Phiên MFA không hợp lệ hoặc đã hết hạn");
        }
        User user = load(userId);
        user.setLastLoginAt(LocalDateTime.now());
        userRepository.save(user);
        return issueToken(user);
    }

    /** UC-03: email an OTP to a registered, active account. Always silent about whether it matched. */
    @Transactional(readOnly = true)
    public void forgotPassword(ForgotPasswordRequest request) {
        userRepository.findByEmail(request.email()).ifPresent(user -> {
            if (!Boolean.FALSE.equals(user.getIsActive())) {
                String code = otpStore.issue(resetKey(user.getId()), user.getId());
                emailService.send(user.getEmail(), "Đặt lại mật khẩu Khoga",
                        "Mã OTP đặt lại mật khẩu của bạn là: " + code + " (hết hạn sau 10 phút).");
            }
        });
        // No signal about existence — prevents email enumeration (BR-16).
    }

    /** UC-04: validate a reset OTP without consuming it; throws on wrong/expired/locked (BR-17). */
    public void verifyOtp(VerifyOtpRequest request) {
        User user = userRepository.findByEmail(request.email())
                .orElseThrow(() -> new AppException("Mã OTP không đúng hoặc đã hết hạn"));
        requireOtp(otpStore.verify(resetKey(user.getId()), request.otp()));
    }

    /** UC-05: set a new password after a valid OTP, then invalidate the OTP and clear any lockout. */
    @Transactional
    public void resetPassword(ResetPasswordRequest request) {
        User user = userRepository.findByEmail(request.email())
                .orElseThrow(() -> new AppException("Mã OTP không đúng hoặc đã hết hạn"));
        String key = resetKey(user.getId());
        requireOtp(otpStore.verify(key, request.otp()));
        applyNewPassword(user, request.newPassword());
        user.setFailedAttempts(0);
        user.setLockExpiryAt(null);
        userRepository.save(user);
        otpStore.consume(key);
        auditLogService.record(ActionType.UPDATE, "User", null, "{\"event\":\"PASSWORD_RESET\"}", user.getId());
    }

    /** UC-06: only valid while {@code mustChangePassword} is set; clears the flag and re-issues a token. */
    @Transactional
    public LoginResponse forcePasswordChange(UUID userId, ForcePasswordChangeRequest request) {
        User user = load(userId);
        if (!Boolean.TRUE.equals(user.getMustChangePassword())) {
            throw new AppException("Tài khoản không ở trạng thái bắt buộc đổi mật khẩu");
        }
        applyNewPassword(user, request.newPassword());
        user.setMustChangePassword(false);
        userRepository.save(user);
        auditLogService.record(ActionType.UPDATE, "User", null, "{\"event\":\"FORCE_PASSWORD_CHANGE\"}", userId);
        return issueToken(user);
    }

    /**
     * UC-09: change password while logged in — verify the current one, apply policy, audit, and
     * re-issue a token. Bumping {@code tokenVersion} (in {@link #applyNewPassword}) revokes every
     * previously-issued token (BR-18); returning a fresh one keeps the *current* session alive while
     * other devices are logged out.
     */
    @Transactional
    public LoginResponse changePassword(UUID userId, ChangePasswordRequest request) {
        User user = load(userId);
        if (!passwordEncoder.matches(request.currentPassword(), user.getPasswordHash())) {
            throw new AppException("Mật khẩu hiện tại không đúng");
        }
        applyNewPassword(user, request.newPassword());
        userRepository.save(user);
        auditLogService.record(ActionType.UPDATE, "User", null, "{\"event\":\"PASSWORD_CHANGE\"}", userId);
        return issueToken(user);
    }

    /**
     * UC-02: stateless logout. The client discards the token; we do NOT close any open POS shift
     * (BR-60). Real server-side token invalidation (BR-18) is deferred to P4.
     */
    public void logout(UUID userId) {
        // no-op by design
    }

    private boolean isLocked(User user) {
        return user.getLockExpiryAt() != null && user.getLockExpiryAt().isAfter(LocalDateTime.now());
    }

    /**
     * Reached only after {@link #isLocked} returned false. If a {@code lockExpiryAt} is still set
     * here, the lock has expired — wipe the stale failure count so BR-11 grants a fresh set of
     * attempts instead of re-locking on the very next mistake.
     */
    private void clearExpiredLock(User user) {
        if (user.getLockExpiryAt() != null) {
            user.setFailedAttempts(0);
            user.setLockExpiryAt(null);
        }
    }

    private void registerFailure(User user) {
        int attempts = (user.getFailedAttempts() == null ? 0 : user.getFailedAttempts()) + 1;
        user.setFailedAttempts(attempts);
        if (attempts >= MAX_FAILED_ATTEMPTS) {
            user.setLockExpiryAt(LocalDateTime.now().plusMinutes(LOCK_MINUTES));
        }
        userRepository.save(user);
    }

    /** BR-14 is enforced by {@link StrongPassword} on the DTO; BR-15: new must differ from current. */
    private void applyNewPassword(User user, String newPassword) {
        if (user.getPasswordHash() != null && passwordEncoder.matches(newPassword, user.getPasswordHash())) {
            throw new AppException("Mật khẩu mới phải khác mật khẩu hiện tại");   // BR-15
        }
        user.setPasswordHash(passwordEncoder.encode(newPassword));
        user.setPasswordLastChangedAt(LocalDateTime.now());
        user.setTokenVersion(tokenVersion(user) + 1);     // BR-18: revoke all tokens issued so far
    }

    private LoginResponse issueToken(User user) {
        UUID storeId = user.getStore() != null ? user.getStore().getId() : null;
        String token = tokenProvider.generateToken(user.getId(), user.getRole(), storeId, tokenVersion(user));
        return LoginResponse.authenticated(token, user.getRole(), Boolean.TRUE.equals(user.getMustChangePassword()));
    }

    /** BR-18 anchor, null-safe (legacy rows read as 0). */
    private static int tokenVersion(User user) {
        return user.getTokenVersion() != null ? user.getTokenVersion() : 0;
    }

    /** BR-83: HQ role + global flag on + a deliverable email. No email → can't MFA, fall through to token. */
    private boolean needsMfa(User user) {
        return HQ_ROLES.contains(user.getRole())
                && systemConfig.getGlobalBoolean("HQ_MFA_REQUIRED", true)
                && user.getEmail() != null && !user.getEmail().isBlank();
    }

    private LoginResponse startMfaChallenge(User user) {
        String mfaToken = UUID.randomUUID().toString();
        String code = otpStore.issue(mfaToken, user.getId());
        emailService.send(user.getEmail(), "Mã xác thực đăng nhập Khoga",
                "Mã OTP đăng nhập của bạn là: " + code + " (hết hạn sau 10 phút).");
        return LoginResponse.mfaRequired(mfaToken);
    }

    /** Maps a non-OK OTP result to the right business error (BR-16/BR-17). */
    private void requireOtp(OtpStore.Result result) {
        switch (result) {
            case OK -> { /* valid */ }
            case INVALID -> throw new AppException("Mã OTP không đúng");
            case LOCKED -> throw new AppException("Đã nhập sai OTP quá số lần cho phép, vui lòng yêu cầu mã mới");
            default -> throw new AppException("Mã OTP không đúng hoặc đã hết hạn"); // EXPIRED / NOT_FOUND
        }
    }

    private static String resetKey(UUID userId) {
        return "RESET:" + userId;
    }

    private User load(UUID userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy người dùng"));
    }
}
