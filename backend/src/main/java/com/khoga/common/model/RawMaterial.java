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

    private String code;
    private String name;
    private String unit;
    private BigDecimal suggestedMinThreshold;
    private BigDecimal standardCost;
    private Boolean isActive;
    private String category;
}
