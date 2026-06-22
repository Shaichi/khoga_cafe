package com.khoga.auth;

import com.khoga.audit.AuditLogService;
import com.khoga.auth.dto.ChangePasswordRequest;
import com.khoga.auth.dto.ForcePasswordChangeRequest;
import com.khoga.auth.dto.LoginRequest;
import com.khoga.auth.dto.LoginResponse;
import com.khoga.common.exception.AppException;
import com.khoga.common.exception.ResourceNotFoundException;
import com.khoga.common.model.User;
import com.khoga.common.model.enums.ActionType;
import com.khoga.common.repository.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
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

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider tokenProvider;
    private final AuditLogService auditLogService;

    public AuthService(UserRepository userRepository, PasswordEncoder passwordEncoder,
                       JwtTokenProvider tokenProvider, AuditLogService auditLogService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.tokenProvider = tokenProvider;
        this.auditLogService = auditLogService;
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

        user.setFailedAttempts(0);
        user.setLockExpiryAt(null);
        user.setLastLoginAt(LocalDateTime.now());
        userRepository.save(user);
        return issueToken(user);
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

    /** UC-09: change password while logged in — verify the current one, apply policy, audit. */
    @Transactional
    public void changePassword(UUID userId, ChangePasswordRequest request) {
        User user = load(userId);
        if (!passwordEncoder.matches(request.currentPassword(), user.getPasswordHash())) {
            throw new AppException("Mật khẩu hiện tại không đúng");
        }
        applyNewPassword(user, request.newPassword());
        userRepository.save(user);
        auditLogService.record(ActionType.UPDATE, "User", null, "{\"event\":\"PASSWORD_CHANGE\"}", userId);
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
    }

    private LoginResponse issueToken(User user) {
        UUID storeId = user.getStore() != null ? user.getStore().getId() : null;
        String token = tokenProvider.generateToken(user.getId(), user.getRole(), storeId);
        return new LoginResponse(token, user.getRole(), Boolean.TRUE.equals(user.getMustChangePassword()));
    }

    private User load(UUID userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy người dùng"));
    }
}
