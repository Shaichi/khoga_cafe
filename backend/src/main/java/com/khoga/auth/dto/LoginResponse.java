package com.khoga.auth.dto;

import com.khoga.common.model.enums.Role;

public record LoginResponse(String token, Role role, boolean mustChangePassword) {
}
