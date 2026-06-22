package com.khoga.user.dto;

import com.khoga.common.model.enums.ActionType;
import com.khoga.common.model.enums.Role;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/** UC-13: full profile + recent account-activity trail (BR-21). */
public record UserDetailResponse(
        UUID id, String employeeId, String username, String fullName,
        Role role, String email, String phone, UUID storeId, boolean active,
        LocalDateTime lastLoginAt, List<ActivityEntry> recentActivity) {

    public record ActivityEntry(ActionType actionType, String entityAffected, LocalDateTime at) {
    }
}
