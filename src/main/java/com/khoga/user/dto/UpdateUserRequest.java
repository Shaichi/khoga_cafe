package com.khoga.user.dto;

import com.khoga.common.model.enums.Role;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Pattern;

import java.util.UUID;

/** UC-12: role/branch/contact edits. Status changes go through the activate/deactivate endpoints. */
public record UpdateUserRequest(
        Role role,
        UUID storeId,
        @Email(message = "Email không hợp lệ") String email,
        @Pattern(regexp = "^$|^[0-9]{10,12}$", message = "Số điện thoại phải có 10–12 chữ số") String phone) {
}
