package com.khoga.order.dto;

import java.math.BigDecimal;
import java.util.List;

/** An order line with its toppings (UC-73). */
public record OrderItemLine(
        String menuItemName,
        Integer quantity,
        BigDecimal unitPrice,
        List<OrderToppingLine> toppings) {
}
