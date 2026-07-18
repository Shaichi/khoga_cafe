package com.khoga.staff.dto;

import java.time.LocalDateTime;
import java.util.UUID;

public record ManualAttendanceRequest(
        UUID userId,
        LocalDateTime checkInAt,
        LocalDateTime checkOutAt
) {
}
