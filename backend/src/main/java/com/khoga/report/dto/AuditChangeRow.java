package com.khoga.report.dto;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * One immutable audit-trail row for the change-history reports — price/voucher changes (UC-77) and
 * account changes (UC-83). Sourced read-only from {@code AUDIT_LOG} (BR-68/BR-81).
 */
public record AuditChangeRow(
        UUID id,
        LocalDateTime timestamp,
        UUID actorId,
        String actor,
        String entity,
        String action,
        String oldValue,
        String newValue) {
}
