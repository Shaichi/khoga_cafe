package com.khoga.customer.dto;

import java.time.LocalDateTime;
import java.util.UUID;

public record CustomerResponse(
        UUID id, String phone, String fullName, String email, Integer points,
        LocalDateTime consentAt, String consentVersion) {
}
