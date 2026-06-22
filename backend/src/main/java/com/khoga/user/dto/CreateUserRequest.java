package com.khoga.user.dto;

import com.khoga.common.model.enums.Role;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;

import java.util.UUID;

/**
 * Username + temporary password are auto-generated (BR-22/57/58); the admin supplies identity,
 * role, contact and (for branch roles) the store.
 */
public record CreateUserRequest(
        @NotBlank(message = "Họ tên không được để trống") String fullName,
        @NotNull(message = "Vai trò không được để trống") Role role,
        @NotBlank @Email(message = "Email không hợp lệ") String email,
        @Pattern(regexp = "^$|^[0-9]{10,12}$", message = "Số điện thoại phải có 10–12 chữ số") String phone,
        UUID storeId) {
}
