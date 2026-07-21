package com.khoga.auth.dto;

import com.khoga.common.model.enums.Role;

import java.util.UUID;

public record ProfileResponse(
        UUID id, String username, String fullName, String email, String phone, Role role, UUID storeId, String storeName) {
}
