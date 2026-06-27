package com.khoga.common.model;

import jakarta.persistence.*;
import lombok.*;
import java.util.UUID;
import java.time.LocalDateTime;
import java.math.BigDecimal;
import com.khoga.common.model.enums.*;

@Entity
@Table(name = "branchmenustatuss", uniqueConstraints = @UniqueConstraint(columnNames = {"store_id", "menu_item_id"}))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class BranchMenuStatus extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    // Surrogate UUID PK + unique (store_id, menu_item_id) — enforces one availability row per (branch, item).
    @ManyToOne
    @JoinColumn(name = "store_id")
    private Store store;
    @ManyToOne
    @JoinColumn(name = "menu_item_id")
    private MenuItem menuItem;
    private Boolean isAvailable;
}
