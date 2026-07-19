package com.khoga.common.model;

import jakarta.persistence.*;
import lombok.*;
import java.util.UUID;
import java.time.LocalDateTime;
import java.math.BigDecimal;
import com.khoga.common.model.enums.*;

@Entity
@Table(name = "systemconfigs")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class SystemConfig extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(columnDefinition = "nvarchar(255)")
    private String configKey;
    @Column(columnDefinition = "nvarchar(255)")
    private String configValue;
    @Column(columnDefinition = "nvarchar(255)")
    private String scope;
    @ManyToOne
    @JoinColumn(name = "store_id")
    private Store store;
    @Column(columnDefinition = "nvarchar(255)")
    private String updatedBy;
    // updatedAt/createdAt are inherited from BaseEntity (JPA auditing) — do not redeclare.
}
