package com.khoga.pos.dto;

import com.khoga.common.model.enums.ShiftStatus;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

public record ShiftResponse(
        UUID id,
        UUID storeId,
        UUID cashierId,
        String posRegisterId,
        BigDecimal startingCash,
        ShiftStatus status,
        LocalDateTime startTime) {
}
