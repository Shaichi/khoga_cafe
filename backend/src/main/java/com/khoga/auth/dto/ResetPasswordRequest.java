package com.khoga.auth.dto;

import com.khoga.auth.StrongPassword;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

/** UC-05 — set a new password after a valid OTP. New password must meet the policy (BR-14). */
public record ResetPasswordRequest(
        @NotBlank @Email String email,
        @NotBlank(message = "Mã OTP không được để trống") String otp,
        @StrongPassword String newPassword) {
}
