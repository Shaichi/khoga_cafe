package com.khoga.common.model;

import jakarta.persistence.*;
import lombok.*;
import java.util.UUID;
import java.time.LocalDateTime;
import java.math.BigDecimal;
import com.khoga.common.model.enums.*;

@Entity
@Table(name = "rawmaterials")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class RawMaterial extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(columnDefinition = "nvarchar(255)")
    private String code;
    @Column(columnDefinition = "nvarchar(255)")
    private String name;
    @Column(columnDefinition = "nvarchar(255)")
    private String unit;
    private BigDecimal suggestedMinThreshold;
    private BigDecimal standardCost;
    private Boolean isActive;
    @Column(columnDefinition = "nvarchar(255)")
    private String category;
}
