package com.khoga.user;

import com.khoga.common.model.AuditLog;
import com.khoga.common.model.User;
import com.khoga.user.dto.UserDetailResponse;
import com.khoga.user.dto.UserResponse;

import java.util.List;
import java.util.UUID;

/** Hand-written entity→DTO mapper (project convention: no MapStruct). */
final class UserMapper {

    private UserMapper() {
    }

    static UserResponse toResponse(User u) {
        return new UserResponse(
                u.getId(), u.getEmployeeId(), u.getUsername(), u.getFullName(),
                u.getRole(), u.getEmail(), u.getPhone(), storeId(u), Boolean.TRUE.equals(u.getIsActive()));
    }

    static UserDetailResponse toDetail(User u, List<AuditLog> activity) {
        List<UserDetailResponse.ActivityEntry> entries = activity.stream()
                .map(a -> new UserDetailResponse.ActivityEntry(a.getActionType(), a.getEntityAffected(), a.getCreatedAt()))
                .toList();
        return new UserDetailResponse(
                u.getId(), u.getEmployeeId(), u.getUsername(), u.getFullName(),
                u.getRole(), u.getEmail(), u.getPhone(), storeId(u), Boolean.TRUE.equals(u.getIsActive()),
                u.getLastLoginAt(), entries);
    }

    private static UUID storeId(User u) {
        return u.getStore() != null ? u.getStore().getId() : null;
    }
}
