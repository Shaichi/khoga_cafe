package com.khoga.order.dto;

import java.math.BigDecimal;

/** A topping selected on an order line (UC-73). */
public record OrderToppingLine(
        String name,
        Integer quantity,
        BigDecimal unitPrice) {
}
