package com.khoga.order.dto;

import jakarta.validation.constraints.NotBlank;

/** SM authorization to force-abandon a shift's remaining READY orders at shift close (BR-88). */
public record ForceAbandonRequest(@NotBlank String smApprovalPin) {
}
