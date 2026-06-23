package com.khoga.common.model;

import jakarta.persistence.*;
import lombok.*;
import java.util.UUID;
import java.time.LocalDateTime;
import java.math.BigDecimal;
import com.khoga.common.model.enums.*;

@Entity
@Table(name = "optiontoppings")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class OptionTopping extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    // Global Topping doesn't have menuItem link anymore
    private String name;
    private BigDecimal price;
    private Boolean isActive;
}
