package com.khoga.common.model;

import jakarta.persistence.*;
import lombok.*;
import java.util.UUID;

@Entity
@Table(name = "menu_item_topping_mappings", uniqueConstraints = @UniqueConstraint(columnNames = {"menu_item_id", "option_topping_id"}))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class MenuItemToppingMapping extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne
    @JoinColumn(name = "menu_item_id", nullable = false)
    private MenuItem menuItem;

    @ManyToOne
    @JoinColumn(name = "option_topping_id", nullable = false)
    private OptionTopping optionTopping;
    
    // Optional: override price for specific menu item?
    // private BigDecimal overriddenPrice;
}
