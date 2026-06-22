package com.khoga.auth.dto;

import com.khoga.auth.StrongPassword;
import jakarta.validation.constraints.NotBlank;

public record ChangePasswordRequest(
        @NotBlank(message = "Mật khẩu hiện tại không được để trống") String currentPassword,
        @NotBlank @StrongPassword String newPassword) {
}
