package com.khoga.common.repository;

import com.khoga.common.model.AuditLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface AuditLogRepository extends JpaRepository<AuditLog, UUID> {

    /** UC-13 / BR-21: recent account-activity trail for a user (newest first). */
    List<AuditLog> findTop50ByUserIdOrderByCreatedAtDesc(UUID userId);
}
