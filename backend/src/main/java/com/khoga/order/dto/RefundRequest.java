package com.khoga.order.dto;

import com.khoga.common.model.enums.RefundType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

/**
 * UC-75 SM-authorized refund / comp remake (BR-67/BR-09). The Store Manager authorizes by entering
 * their attendance PIN; {@code amount} is the cash/gateway figure for a REFUND (ignored for COMP_REMAKE).
 */
public record RefundRequest(
        @NotNull RefundType refundType,
        BigDecimal amount,
        @NotBlank String reason,
        String notes,
        @NotBlank String smApprovalPin) {
}
