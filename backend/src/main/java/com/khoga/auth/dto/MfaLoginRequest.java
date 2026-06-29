package com.khoga.auth.dto;

import jakarta.validation.constraints.NotBlank;

/** BR-83 — complete an HQ login by submitting the emailed OTP against the challenge token. */
public record MfaLoginRequest(
        @NotBlank(message = "Thiếu mã phiên MFA") String mfaToken,
        @NotBlank(message = "Mã OTP không được để trống") String otp) {
}
