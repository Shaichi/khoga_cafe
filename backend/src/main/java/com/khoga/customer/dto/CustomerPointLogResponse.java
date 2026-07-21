package com.khoga.customer.dto;

import java.time.LocalDateTime;
import java.util.UUID;

public record CustomerPointLogResponse(
    UUID id,
    LocalDateTime createdAt,
    String date,
    String type,
    Integer pointsDelta,
    String reason,
    String performedBy
) {}
