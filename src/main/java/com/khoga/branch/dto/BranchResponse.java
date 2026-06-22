package com.khoga.branch.dto;

import java.time.LocalDateTime;
import java.util.UUID;

public record BranchResponse(
        UUID id, String name, String address, String phone, boolean active,
        LocalDateTime createdAt, LocalDateTime updatedAt) {
}
