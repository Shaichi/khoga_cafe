package com.khoga.auth.dto;

import com.khoga.auth.StrongPassword;
import jakarta.validation.constraints.NotBlank;

public record ForcePasswordChangeRequest(
        @NotBlank @StrongPassword String newPassword) {
}
