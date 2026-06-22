package com.khoga.auth;

import com.khoga.audit.AuditLogService;
import com.khoga.auth.dto.ChangePasswordRequest;
import com.khoga.auth.dto.ForcePasswordChangeRequest;
import com.khoga.auth.dto.LoginRequest;
import com.khoga.auth.dto.LoginResponse;
import com.khoga.common.exception.AppException;
import com.khoga.common.model.User;
import com.khoga.common.model.enums.ActionType;
import com.khoga.common.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * P0.8 unit tests for the Auth MVP service. A real {@link BCryptPasswordEncoder} is used so password
 * hashing/matching is exercised for real; repositories and collaborators are mocked.
 */
@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;
    @Mock
    private JwtTokenProvider tokenProvider;
    @Mock
    private AuditLogService auditLogService;

    private final PasswordEncoder encoder = new BCryptPasswordEncoder();
    private AuthService authService;

    @BeforeEach
    void setUp() {
        authService = new AuthService(userRepository, encoder, tokenProvider, auditLogService);
    }

    private User activeUser(String rawPassword) {
        User u = new User();
        u.setId(UUID.randomUUID());
        u.setUsername("cashier1");
        u.setPasswordHash(encoder.encode(rawPassword));
        u.setRole(com.khoga.common.model.enums.Role.CASHIER);
        u.setIsActive(true);
        u.setMustChangePassword(false);
        u.setFailedAttempts(0);
        return u;
    }

    @Test
    void login_withCorrectCredentials_returnsTokenAndResetsFailures() {
        User u = activeUser("Secret@123");
        u.setFailedAttempts(3);
        when(userRepository.findByUsername("cashier1")).thenReturn(Optional.of(u));
        when(tokenProvider.generateToken(any(), eq(com.khoga.common.model.enums.Role.CASHIER), any()))
                .thenReturn("jwt-token");

        LoginResponse response = authService.login(new LoginRequest("cashier1", "Secret@123"));

        assertEquals("jwt-token", response.token());
        assertFalse(response.mustChangePassword());
        assertEquals(0, u.getFailedAttempts());
        assertNull(u.getLockExpiryAt());
        assertNotNull(u.getLastLoginAt());
    }

    @Test
    void login_fifthWrongPassword_locksAccount() {
        User u = activeUser("Secret@123");
        u.setFailedAttempts(4);
        when(userRepository.findByUsername("cashier1")).thenReturn(Optional.of(u));

        assertThrows(AppException.class, () -> authService.login(new LoginRequest("cashier1", "wrong")));

        assertEquals(5, u.getFailedAttempts());
        assertNotNull(u.getLockExpiryAt());
        assertTrue(u.getLockExpiryAt().isAfter(LocalDateTime.now()));
    }

    @Test
    void login_afterLockExpires_grantsFreshAttemptsInsteadOfReLocking() {
        User u = activeUser("Secret@123");
        u.setFailedAttempts(5);
        u.setLockExpiryAt(LocalDateTime.now().minusMinutes(1)); // lock already expired
        when(userRepository.findByUsername("cashier1")).thenReturn(Optional.of(u));

        // One wrong password must NOT immediately re-lock: counter resets to 0 then increments to 1.
        assertThrows(AppException.class, () -> authService.login(new LoginRequest("cashier1", "wrong")));

        assertEquals(1, u.getFailedAttempts());
        assertNull(u.getLockExpiryAt());
    }

    @Test
    void login_lockedAccount_isRejectedEvenWithCorrectPassword() {
        User u = activeUser("Secret@123");
        u.setLockExpiryAt(LocalDateTime.now().plusMinutes(10));
        when(userRepository.findByUsername("cashier1")).thenReturn(Optional.of(u));

        assertThrows(AppException.class, () -> authService.login(new LoginRequest("cashier1", "Secret@123")));
    }

    @Test
    void login_inactiveAccount_isRejected() {
        User u = activeUser("Secret@123");
        u.setIsActive(false);
        when(userRepository.findByUsername("cashier1")).thenReturn(Optional.of(u));

        assertThrows(AppException.class, () -> authService.login(new LoginRequest("cashier1", "Secret@123")));
    }

    @Test
    void changePassword_withWrongCurrent_throws() {
        User u = activeUser("Secret@123");
        when(userRepository.findById(u.getId())).thenReturn(Optional.of(u));

        assertThrows(AppException.class, () ->
                authService.changePassword(u.getId(), new ChangePasswordRequest("wrong", "NewSecret@123")));
    }

    @Test
    void changePassword_sameAsCurrent_throws() {
        User u = activeUser("Secret@123");
        when(userRepository.findById(u.getId())).thenReturn(Optional.of(u));

        assertThrows(AppException.class, () ->
                authService.changePassword(u.getId(), new ChangePasswordRequest("Secret@123", "Secret@123")));
    }

    @Test
    void changePassword_valid_updatesHashAndAudits() {
        User u = activeUser("Secret@123");
        when(userRepository.findById(u.getId())).thenReturn(Optional.of(u));

        authService.changePassword(u.getId(), new ChangePasswordRequest("Secret@123", "NewSecret@123"));

        assertTrue(encoder.matches("NewSecret@123", u.getPasswordHash()));
        assertNotNull(u.getPasswordLastChangedAt());
        verify(auditLogService).record(eq(ActionType.UPDATE), eq("User"), any(), any(), eq(u.getId()));
    }

    @Test
    void forcePasswordChange_whenNotRequired_throws() {
        User u = activeUser("Secret@123");
        when(userRepository.findById(u.getId())).thenReturn(Optional.of(u));

        assertThrows(AppException.class, () ->
                authService.forcePasswordChange(u.getId(), new ForcePasswordChangeRequest("NewSecret@123")));
    }

    @Test
    void forcePasswordChange_whenRequired_clearsFlagAndIssuesToken() {
        User u = activeUser("Secret@123");
        u.setMustChangePassword(true);
        when(userRepository.findById(u.getId())).thenReturn(Optional.of(u));
        when(tokenProvider.generateToken(any(), any(), any())).thenReturn("fresh-token");

        LoginResponse response = authService.forcePasswordChange(u.getId(),
                new ForcePasswordChangeRequest("NewSecret@123"));

        assertEquals("fresh-token", response.token());
        assertFalse(response.mustChangePassword());
        assertFalse(Boolean.TRUE.equals(u.getMustChangePassword()));
        assertTrue(encoder.matches("NewSecret@123", u.getPasswordHash()));
    }
}
