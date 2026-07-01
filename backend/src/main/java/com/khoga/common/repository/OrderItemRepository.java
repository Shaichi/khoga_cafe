package com.khoga.common.repository;

import com.khoga.common.model.OrderItem;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface OrderItemRepository extends JpaRepository<OrderItem, UUID> {

    List<OrderItem> findByOrderId(UUID orderId);

    long countByOrderId(UUID orderId);

    /**
     * UC-28/76 units sold per menu item over a window (COMPLETED orders), most-sold first.
     * Optional branch scope (null = chain-wide). Use a {@link Pageable} of size N for best-sellers,
     * or unpaged for the full COGS basis.
     */
    @Query("select new com.khoga.report.dto.BestSellerRow(oi.menuItem.id, oi.menuItem.name, "
            + "coalesce(sum(oi.quantity), 0)) from OrderItem oi "
            + "where oi.order.status = com.khoga.common.model.enums.OrderStatus.COMPLETED "
            + "and oi.order.createdAt >= :from and oi.order.createdAt < :to "
            + "and (:storeId is null or oi.order.store.id = :storeId) "
            + "group by oi.menuItem.id, oi.menuItem.name order by sum(oi.quantity) desc")
    List<com.khoga.report.dto.BestSellerRow> soldByMenuItem(@Param("storeId") UUID storeId,
                                                            @Param("from") LocalDateTime from,
                                                            @Param("to") LocalDateTime to,
                                                            Pageable pageable);

    /**
     * UC-76 per-menu-item sales aggregate (units + gross revenue) over COMPLETED orders in a window,
     * optional branch scope (null = chain-wide). The COGS basis for the margin report (BR-66).
     */
    @Query("select new com.khoga.report.dto.SoldItemAggregate(oi.menuItem.id, oi.menuItem.name, "
            + "coalesce(sum(oi.quantity), 0), coalesce(sum(oi.quantity * oi.unitPrice), 0)) from OrderItem oi "
            + "where oi.order.status = com.khoga.common.model.enums.OrderStatus.COMPLETED "
            + "and oi.order.createdAt >= :from and oi.order.createdAt < :to "
            + "and (:storeId is null or oi.order.store.id = :storeId) "
            + "group by oi.menuItem.id, oi.menuItem.name")
    List<com.khoga.report.dto.SoldItemAggregate> soldAggregateByMenuItem(@Param("storeId") UUID storeId,
                                                                         @Param("from") LocalDateTime from,
                                                                         @Param("to") LocalDateTime to);
}
