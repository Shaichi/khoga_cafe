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
    @Mock
    private OtpStore otpStore;
    @Mock
    private com.khoga.integration.EmailService emailService;
    @Mock
    private com.khoga.config.SystemConfigService systemConfig;

    private final PasswordEncoder encoder = new BCryptPasswordEncoder();
    private AuthService authService;

    @BeforeEach
    void setUp() {
        authService = new AuthService(userRepository, encoder, tokenProvider, auditLogService,
                otpStore, emailService, systemConfig);
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

    // ----- P1B: forgot-password OTP flow (UC-03/04/05) -----

    private User hqUser(String rawPassword) {
        User u = activeUser(rawPassword);
        u.setUsername("ceo");
        u.setRole(com.khoga.common.model.enums.Role.CEOVIEWER);
        u.setEmail("ceo@khoga.com");
        return u;
    }

    @Test
    void forgotPassword_existingActiveEmail_issuesAndEmailsOtp() {
        User u = hqUser("Secret@123");
        when(userRepository.findByEmail("ceo@khoga.com")).thenReturn(Optional.of(u));
        when(otpStore.issue(eq("RESET:" + u.getId()), eq(u.getId()))).thenReturn("123456");

        authService.forgotPassword(new com.khoga.auth.dto.ForgotPasswordRequest("ceo@khoga.com"));

        verify(otpStore).issue("RESET:" + u.getId(), u.getId());
        verify(emailService).send(eq("ceo@khoga.com"), any(), org.mockito.ArgumentMatchers.contains("123456"));
    }

    @Test
    void forgotPassword_unknownEmail_isSilentNoOp() {
        when(userRepository.findByEmail("nobody@khoga.com")).thenReturn(Optional.empty());

        authService.forgotPassword(new com.khoga.auth.dto.ForgotPasswordRequest("nobody@khoga.com"));

        org.mockito.Mockito.verifyNoInteractions(otpStore, emailService);
    }

    @Test
    void verifyOtp_invalidCode_throws() {
        User u = hqUser("Secret@123");
        when(userRepository.findByEmail("ceo@khoga.com")).thenReturn(Optional.of(u));
        when(otpStore.verify("RESET:" + u.getId(), "000000")).thenReturn(OtpStore.Result.INVALID);

        assertThrows(AppException.class, () ->
                authService.verifyOtp(new com.khoga.auth.dto.VerifyOtpRequest("ceo@khoga.com", "000000")));
    }

    @Test
    void resetPassword_validOtp_setsPasswordConsumesAndAudits() {
        User u = hqUser("Secret@123");
        when(userRepository.findByEmail("ceo@khoga.com")).thenReturn(Optional.of(u));
        when(otpStore.verify("RESET:" + u.getId(), "123456")).thenReturn(OtpStore.Result.OK);

        authService.resetPassword(
                new com.khoga.auth.dto.ResetPasswordRequest("ceo@khoga.com", "123456", "Brand@New9"));

        assertTrue(encoder.matches("Brand@New9", u.getPasswordHash()));
        verify(otpStore).consume("RESET:" + u.getId());
        verify(auditLogService).record(eq(ActionType.UPDATE), eq("User"), any(), any(), eq(u.getId()));
    }

    @Test
    void resetPassword_lockedOtp_throws() {
        User u = hqUser("Secret@123");
        when(userRepository.findByEmail("ceo@khoga.com")).thenReturn(Optional.of(u));
        when(otpStore.verify("RESET:" + u.getId(), "999999")).thenReturn(OtpStore.Result.LOCKED);

        assertThrows(AppException.class, () -> authService.resetPassword(
                new com.khoga.auth.dto.ResetPasswordRequest("ceo@khoga.com", "999999", "Brand@New9")));
    }

    // ----- P1B: HQ login MFA (BR-83) -----

    @Test
    void login_hqWithMfaEnabled_returnsMfaRequiredWithoutToken() {
        User u = hqUser("Secret@123");
        when(userRepository.findByUsername("ceo")).thenReturn(Optional.of(u));
        when(systemConfig.getGlobalBoolean(eq("HQ_MFA_REQUIRED"), org.mockito.ArgumentMatchers.anyBoolean()))
                .thenReturn(true);
        when(otpStore.issue(any(), eq(u.getId()))).thenReturn("654321");

        LoginResponse response = authService.login(new LoginRequest("ceo", "Secret@123"));

        assertEquals(LoginResponse.MFA_REQUIRED, response.status());
        assertNull(response.token());
        assertNotNull(response.mfaToken());
        verify(emailService).send(eq("ceo@khoga.com"), any(), org.mockito.ArgumentMatchers.contains("654321"));
        org.mockito.Mockito.verifyNoInteractions(tokenProvider); // no JWT until OTP cleared
    }

    @Test
    void login_hqWithMfaDisabled_issuesTokenDirectly() {
        User u = hqUser("Secret@123");
        when(userRepository.findByUsername("ceo")).thenReturn(Optional.of(u));
        when(systemConfig.getGlobalBoolean(eq("HQ_MFA_REQUIRED"), org.mockito.ArgumentMatchers.anyBoolean()))
                .thenReturn(false);
        when(tokenProvider.generateToken(any(), eq(com.khoga.common.model.enums.Role.CEOVIEWER), any()))
                .thenReturn("hq-token");

        LoginResponse response = authService.login(new LoginRequest("ceo", "Secret@123"));

        assertEquals(LoginResponse.AUTHENTICATED, response.status());
        assertEquals("hq-token", response.token());
    }

    @Test
    void loginMfa_validOtp_issuesToken() {
        User u = hqUser("Secret@123");
        when(otpStore.verify("mfa-1", "654321")).thenReturn(OtpStore.Result.OK);
        when(otpStore.consume("mfa-1")).thenReturn(u.getId());
        when(userRepository.findById(u.getId())).thenReturn(Optional.of(u));
        when(tokenProvider.generateToken(any(), any(), any())).thenReturn("hq-token");

        LoginResponse response = authService.loginMfa(new com.khoga.auth.dto.MfaLoginRequest("mfa-1", "654321"));

        assertEquals("hq-token", response.token());
        assertNotNull(u.getLastLoginAt());
    }

    @Test
    void loginMfa_wrongOtp_throws() {
        when(otpStore.verify("mfa-1", "000000")).thenReturn(OtpStore.Result.INVALID);

        assertThrows(AppException.class, () ->
                authService.loginMfa(new com.khoga.auth.dto.MfaLoginRequest("mfa-1", "000000")));
    }
}
