package com.khoga.common.model;

import jakarta.persistence.*;
import lombok.*;
import java.util.UUID;
import java.time.LocalDateTime;
import java.math.BigDecimal;
import com.khoga.common.model.enums.*;

@Entity
@Table(name = "auditlogs", indexes = {
        // P4 perf — UC-77/83 change-history filters by entity + time, and by actor + time.
        @Index(name = "idx_audit_entity_created", columnList = "entity_affected, created_at"),
        @Index(name = "idx_audit_user_created", columnList = "user_id, created_at")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class AuditLog extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;
    @Enumerated(EnumType.STRING)
    private ActionType actionType;
    @Column(columnDefinition = "nvarchar(255)")
    private String entityAffected;
    @Column(columnDefinition = "nvarchar(255)")
    private String oldValueJson;
    @Column(columnDefinition = "nvarchar(255)")
    private String newValueJson;
}
