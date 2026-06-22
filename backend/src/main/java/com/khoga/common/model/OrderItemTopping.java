package com.khoga.common.model;

import jakarta.persistence.*;
import lombok.*;
import java.util.UUID;
import java.time.LocalDateTime;
import java.math.BigDecimal;
import com.khoga.common.model.enums.*;

@Entity
@Table(name = "orderitemtoppings")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class OrderItemTopping extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne
    @JoinColumn(name = "order_item_id")
    private OrderItem orderItem;
    @ManyToOne
    @JoinColumn(name = "topping_id")
    private OptionTopping topping;
    private Integer quantity;
    private BigDecimal unitPrice;
}
