package com.khoga.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

/** UC-03 — request an OTP to the account's registered email. */
public record ForgotPasswordRequest(
        @NotBlank(message = "Email không được để trống") @Email(message = "Email không hợp lệ") String email) {
}
