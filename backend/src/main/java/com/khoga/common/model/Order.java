package com.khoga.common.model;

import jakarta.persistence.*;
import lombok.*;
import java.util.UUID;
import java.time.LocalDateTime;
import java.math.BigDecimal;
import com.khoga.common.model.enums.*;

@Entity
@Table(name = "orders", indexes = {
        // P4 perf — revenue/report + queue lookups over (branch, time) and (status, time).
        @Index(name = "idx_orders_store_created", columnList = "store_id, created_at"),
        @Index(name = "idx_orders_status_created", columnList = "status, created_at"),
        @Index(name = "idx_orders_shift", columnList = "shift_session_id")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Order extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne
    @JoinColumn(name = "store_id")
    private Store store;
    @Column(columnDefinition = "nvarchar(255)")
    private String orderNumber;
    @ManyToOne
    @JoinColumn(name = "shift_session_id")
    private ShiftSession shiftSession;
    @ManyToOne
    @JoinColumn(name = "customer_id")
    private Customer customer;
    @ManyToOne
    @JoinColumn(name = "voucher_id")
    private Voucher voucher;
    @Enumerated(EnumType.STRING)
    private OrderType orderType;
    private BigDecimal subtotal;
    private BigDecimal discount;
    private BigDecimal taxAmount;
    private BigDecimal total;
    @Enumerated(EnumType.STRING)
    private PaymentMethod paymentMethod;
    @Enumerated(EnumType.STRING)
    private PaymentStatus paymentStatus;
    @Enumerated(EnumType.STRING)
    private OrderStatus status;
    /** Loyalty points consumed by redemption on this order (for accrual/rollback, BR-08). */
    private Integer pointsRedeemed;
    /** Loyalty points accrued to the customer when this order is paid (BR-01/BR-69). */
    private Integer pointsEarned;
    /**
     * VietQR gateway transaction reference recorded when the order is paid via the callback
     * (BR-84). Nullable (cash/card orders and unpaid orders have none). Enables reconciliation and
     * idempotent handling of duplicate callbacks — a repeat callback carrying this same ref is a no-op.
     */
    @Column(name = "transaction_ref", columnDefinition = "nvarchar(255)")
    private String transactionRef;
    /**
     * When the order entered READY (BR-88). Auto-abandon measures idle time from this instant, not from
     * {@code updatedAt}, so unrelated writes never reset the abandon clock. Nullable (set on →READY).
     */
    @Column(name = "ready_at")
    private LocalDateTime readyAt;
}
