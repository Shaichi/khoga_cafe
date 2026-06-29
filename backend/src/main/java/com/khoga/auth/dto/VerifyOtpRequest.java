package com.khoga.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

/** UC-04 — verify a password-reset OTP for an email. */
public record VerifyOtpRequest(
        @NotBlank @Email String email,
        @NotBlank(message = "Mã OTP không được để trống") String otp) {
}
