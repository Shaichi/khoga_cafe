package com.khoga.common.model;

import jakarta.persistence.*;
import lombok.*;
import java.util.UUID;
import java.time.LocalDateTime;
import java.math.BigDecimal;
import com.khoga.common.model.enums.*;

@Entity
@Table(name = "stocktransactions")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class StockTransaction extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne
    @JoinColumn(name = "stock_item_id")
    private StockItem stockItem;
    @ManyToOne
    @JoinColumn(name = "manager_id")
    private User manager;
    @Enumerated(EnumType.STRING)
    private TransactionType transactionType;
    /** Signed change applied to the stock balance (after − before); for PHANTOM_USAGE this is the deficit magnitude. */
    private BigDecimal quantity;
    /** Balance snapshot before this movement (audit trail). */
    private BigDecimal quantityBefore;
    /** Balance snapshot after this movement (audit trail). */
    private BigDecimal quantityAfter;
    private String reason;
}
