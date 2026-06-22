package com.khoga.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Pattern;

/**
 * Self-service profile edit (UC-08, BR-19): only contact fields are editable; role/username/branch
 * are not exposed here.
 */
public record ProfileUpdateRequest(
        @Email(message = "Email không hợp lệ") String email,
        @Pattern(regexp = "^$|^[0-9]{10,12}$", message = "Số điện thoại phải có 10–12 chữ số") String phone) {
}
