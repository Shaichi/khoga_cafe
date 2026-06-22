package com.khoga.common.model;

import jakarta.persistence.*;
import lombok.*;
import java.util.UUID;
import java.time.LocalDateTime;
import java.math.BigDecimal;
import com.khoga.common.model.enums.*;

@Entity
@Table(name = "orderrefunds")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class OrderRefund extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne
    @JoinColumn(name = "order_id")
    private Order order;
    @ManyToOne
    @JoinColumn(name = "sm_id")
    private User storeManager;
    @ManyToOne
    @JoinColumn(name = "cashier_id")
    private User cashier;
    @ManyToOne
    @JoinColumn(name = "shift_session_id")
    private ShiftSession shiftSession;
    @Enumerated(EnumType.STRING)
    private RefundType refundType;
    private BigDecimal amount;
    private String reason;
    private String notes;
}
