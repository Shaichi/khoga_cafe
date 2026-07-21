package com.khoga.common.model;

import jakarta.persistence.*;
import lombok.*;
import java.util.UUID;
import java.time.LocalDateTime;
import java.math.BigDecimal;
import com.khoga.common.model.enums.*;

@Entity
@Table(name = "ordercancellations")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class OrderCancellation extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @OneToOne
    @JoinColumn(name = "order_id")
    private Order order;
    @ManyToOne
    @JoinColumn(name = "cashier_id")
    private User cashier;
    @Column(columnDefinition = "nvarchar(255)")
    private String reason;
    @Column(columnDefinition = "nvarchar(255)")
    private String notes;
}
