package com.khoga.user.dto;

import com.khoga.common.model.enums.Role;

import java.util.UUID;

public record UserResponse(
        UUID id, String employeeId, String username, String fullName,
        Role role, String email, String phone, UUID storeId, boolean active) {
}
