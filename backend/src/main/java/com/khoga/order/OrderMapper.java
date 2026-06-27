package com.khoga.order;

import com.khoga.common.model.Order;
import com.khoga.common.model.OrderItem;
import com.khoga.common.model.OrderItemTopping;
import com.khoga.order.dto.OrderDetailResponse;
import com.khoga.order.dto.OrderItemLine;
import com.khoga.order.dto.OrderSummaryResponse;
import com.khoga.order.dto.OrderToppingLine;

import java.util.List;
import java.util.Map;

/** Hand-written Order entity → DTO mappers (per CLAUDE.md convention). */
final class OrderMapper {

    private OrderMapper() {
    }

    static OrderSummaryResponse toSummary(Order o, long itemCount) {
        return new OrderSummaryResponse(
                o.getId(),
                o.getOrderNumber(),
                o.getStatus(),
                o.getPaymentStatus(),
                o.getPaymentMethod(),
                o.getOrderType(),
                o.getTotal(),
                (int) itemCount,
                o.getCustomer() != null ? o.getCustomer().getFullName() : null,
                o.getCreatedAt());
    }

    static OrderDetailResponse toDetail(Order o, List<OrderItem> items,
                                        Map<java.util.UUID, List<OrderItemTopping>> toppingsByItem) {
        List<OrderItemLine> lines = items.stream()
                .map(it -> new OrderItemLine(
                        it.getMenuItem() != null ? it.getMenuItem().getName() : null,
                        it.getQuantity(),
                        it.getUnitPrice(),
                        toppingsByItem.getOrDefault(it.getId(), List.of()).stream()
                                .map(OrderMapper::toToppingLine)
                                .toList()))
                .toList();
        return new OrderDetailResponse(
                o.getId(),
                o.getOrderNumber(),
                o.getStore() != null ? o.getStore().getId() : null,
                o.getStatus(),
                o.getPaymentStatus(),
                o.getPaymentMethod(),
                o.getOrderType(),
                o.getSubtotal(),
                o.getDiscount(),
                o.getTaxAmount(),
                o.getTotal(),
                o.getPointsRedeemed(),
                o.getPointsEarned(),
                o.getCustomer() != null ? o.getCustomer().getFullName() : null,
                lines,
                o.getCreatedAt());
    }

    private static OrderToppingLine toToppingLine(OrderItemTopping t) {
        return new OrderToppingLine(
                t.getTopping() != null ? t.getTopping().getName() : null,
                t.getQuantity(),
                t.getUnitPrice());
    }
}
