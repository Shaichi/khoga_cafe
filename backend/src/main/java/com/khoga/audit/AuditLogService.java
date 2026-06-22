package com.khoga.audit;

import com.khoga.common.model.AuditLog;
import com.khoga.common.model.User;
import com.khoga.common.model.enums.ActionType;
import com.khoga.common.repository.AuditLogRepository;
import com.khoga.common.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Append-only audit trail recorder (BR-68 / BR-80 / BR-81). Callers serialize the before/after state
 * to JSON and call {@link #record}. There is intentionally <b>no</b> update/delete API and no audit
 * controller — entries are immutable once written.
 *
 * <p>Feature subsystems (catalog price changes, voucher changes, account changes, checkout voucher/
 * loyalty application) invoke this from their {@code @Service} layer; AOP/event wiring lands with
 * those features in P1/P2.
 */
@Service
public class AuditLogService {

    private final AuditLogRepository auditLogRepository;
    private final UserRepository userRepository;

    public AuditLogService(AuditLogRepository auditLogRepository, UserRepository userRepository) {
        this.auditLogRepository = auditLogRepository;
        this.userRepository = userRepository;
    }

    /**
     * Writes one immutable audit row.
     *
     * @param actionType     CREATE / UPDATE / DELETE
     * @param entityAffected logical name of the affected entity (e.g. {@code "MenuItem"})
     * @param oldValueJson   JSON snapshot before the change (may be {@code null} for CREATE)
     * @param newValueJson   JSON snapshot after the change (may be {@code null} for DELETE)
     * @param actorUserId    the user who performed the action, or {@code null} for system actions
     */
    @Transactional
    public AuditLog record(ActionType actionType, String entityAffected,
                           String oldValueJson, String newValueJson, UUID actorUserId) {
        AuditLog log = new AuditLog();
        log.setActionType(actionType);
        log.setEntityAffected(entityAffected);
        log.setOldValueJson(oldValueJson);
        log.setNewValueJson(newValueJson);
        if (actorUserId != null) {
            User actor = userRepository.findById(actorUserId).orElse(null);
            log.setUser(actor);
        }
        return auditLogRepository.save(log);
    }
}
