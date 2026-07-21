package com.khoga.staff.dto;

import com.khoga.common.model.enums.Role;

import java.util.UUID;

/** UC-66 branch roster row: identity, role, attendance-PIN status. */
public record StaffRosterResponse(
                UUID userId,
                String employeeId,
                String fullName,
                Role role,
                String phone,
                boolean pinSet,
                boolean pinLocked,
                Boolean isActive) {
}
