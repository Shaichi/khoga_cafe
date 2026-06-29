package com.khoga.auth.dto;

import com.khoga.common.model.enums.Role;

/**
 * Login outcome. For a normal login {@code status="AUTHENTICATED"} and {@code token} is set. For an
 * HQ account requiring MFA (BR-83) the password step returns {@code status="MFA_REQUIRED"} with a
 * one-time {@code mfaToken} (no JWT yet) — the client submits the emailed OTP to {@code /login/mfa}.
 */
public record LoginResponse(String status, String token, Role role, boolean mustChangePassword, String mfaToken) {

    public static final String AUTHENTICATED = "AUTHENTICATED";
    public static final String MFA_REQUIRED = "MFA_REQUIRED";

    public static LoginResponse authenticated(String token, Role role, boolean mustChangePassword) {
        return new LoginResponse(AUTHENTICATED, token, role, mustChangePassword, null);
    }

    public static LoginResponse mfaRequired(String mfaToken) {
        return new LoginResponse(MFA_REQUIRED, null, null, false, mfaToken);
    }
}
