package com.khoga.report;

import com.khoga.common.model.AuditLog;
import com.khoga.common.repository.AuditLogRepository;
import com.khoga.report.dto.AuditChangeRow;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * UC-77 (price & voucher change history) and UC-83 (account-change access review). Both are read-only
 * projections over the immutable {@code AUDIT_LOG} (BR-68/BR-81) — the compensating control for
 * businessadmin's unilateral CRUD. HQ-only; the controller enforces the role.
 */
@Service
public class ChangeHistoryService {

    private final AuditLogRepository auditLogRepository;

    public ChangeHistoryService(AuditLogRepository auditLogRepository) {
        this.auditLogRepository = auditLogRepository;
    }

    /**
     * UC-77 price/voucher change history. {@code type} selects the entity scope:
     * {@code "PRICE"} → MenuItem only, {@code "VOUCHER"} → Voucher only, anything else → both.
     */
    public Page<AuditChangeRow> priceVoucherHistory(LocalDate from, LocalDate to, String type,
                                                    UUID actorFilter, Pageable pageable) {
        List<String> entities = switch (type == null ? "ALL" : type.toUpperCase()) {
            case "PRICE" -> List.of("MenuItem");
            case "VOUCHER" -> List.of("Voucher");
            default -> List.of("MenuItem", "Voucher");
        };
        return query(entities, from, to, actorFilter, pageable);
    }

    /** UC-83 access review — every account (user) change in the window. */
    public Page<AuditChangeRow> accessReview(LocalDate from, LocalDate to, UUID actorFilter, Pageable pageable) {
        return query(List.of("User"), from, to, actorFilter, pageable);
    }

    private Page<AuditChangeRow> query(List<String> entities, LocalDate from, LocalDate to,
                                       UUID actorFilter, Pageable pageable) {
        LocalDateTime fromDt = from.atStartOfDay();
        LocalDateTime toDt = to.plusDays(1).atStartOfDay();
        return auditLogRepository.findChangeHistory(entities, actorFilter, fromDt, toDt, pageable)
                .map(ChangeHistoryService::toRow);
    }

    private static AuditChangeRow toRow(AuditLog a) {
        String actorName = a.getUser() == null ? "—" : a.getUser().getUsername();
        UUID actorId = a.getUser() == null ? null : a.getUser().getId();
        return new AuditChangeRow(a.getId(), a.getCreatedAt(), actorId, actorName,
                a.getEntityAffected(), a.getActionType() == null ? null : a.getActionType().name(),
                a.getOldValueJson(), a.getNewValueJson());
    }
}
