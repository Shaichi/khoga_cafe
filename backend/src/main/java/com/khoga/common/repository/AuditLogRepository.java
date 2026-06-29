package com.khoga.common.repository;

import com.khoga.common.model.AuditLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;
import java.util.UUID;

@Repository
public interface AuditLogRepository extends JpaRepository<AuditLog, UUID> {

    /** UC-13 / BR-21: recent account-activity trail for a user (newest first). */
    List<AuditLog> findTop50ByUserIdOrderByCreatedAtDesc(UUID userId);

    /**
     * UC-77 / UC-83 change-history trail: immutable audit rows for the given entity names within a
     * window, optionally filtered to one actor, newest first (BR-68/BR-81).
     */
    @Query("select a from AuditLog a where a.entityAffected in :entities "
            + "and a.createdAt >= :from and a.createdAt < :to "
            + "and (:actorId is null or a.user.id = :actorId) order by a.createdAt desc")
    Page<AuditLog> findChangeHistory(@Param("entities") Collection<String> entities,
                                     @Param("actorId") UUID actorId,
                                     @Param("from") LocalDateTime from,
                                     @Param("to") LocalDateTime to,
                                     Pageable pageable);

    /** UC-78 — system events of one kind in a window (e.g. {@code "LoyaltyExpiry"} for expired points). */
    List<AuditLog> findByEntityAffectedAndCreatedAtBetween(String entityAffected, LocalDateTime from, LocalDateTime to);
}
