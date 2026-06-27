package com.khoga.common.model;

import jakarta.persistence.*;
import lombok.*;
import java.util.UUID;
import java.time.LocalDateTime;
import java.math.BigDecimal;
import com.khoga.common.model.enums.*;

@Entity
@Table(name = "stockitems", uniqueConstraints = @UniqueConstraint(columnNames = {"store_id", "raw_material_id"}))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class StockItem extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne
    @JoinColumn(name = "store_id")
    private Store store;
    @ManyToOne
    @JoinColumn(name = "raw_material_id")
    private RawMaterial rawMaterial;
    private BigDecimal currentQuantity;
    private BigDecimal minAlertThreshold;
}
