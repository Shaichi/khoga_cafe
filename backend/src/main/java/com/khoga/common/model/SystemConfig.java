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

    private String configKey;
    private String configValue;
    private String scope;
    @ManyToOne
    @JoinColumn(name = "store_id")
    private Store store;
    private String updatedBy;
    // updatedAt/createdAt are inherited from BaseEntity (JPA auditing) — do not redeclare.
}
