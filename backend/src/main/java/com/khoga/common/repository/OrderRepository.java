package com.khoga.common.repository;

import com.khoga.common.model.Order;
import com.khoga.common.model.enums.OrderStatus;
import com.khoga.common.model.enums.PaymentMethod;
import com.khoga.common.model.enums.PaymentStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;
import java.util.UUID;

@Repository
public interface OrderRepository extends JpaRepository<Order, UUID> {

    boolean existsByStoreIdAndStatusIn(UUID storeId, Collection<OrderStatus> statuses);

    boolean existsByShiftSessionIdAndStatusIn(UUID shiftSessionId, Collection<OrderStatus> statuses);

    List<Order> findByShiftSessionIdAndStatus(UUID shiftSessionId, OrderStatus status);

    List<Order> findTop50ByCustomerIdOrderByCreatedAtDesc(UUID customerId);

    /** Live barista queue (UC-57): active orders at a branch, oldest first (FIFO). */
    List<Order> findByStoreIdAndStatusInOrderByCreatedAtAsc(UUID storeId, Collection<OrderStatus> statuses);

    /** READY orders that became stale (last touched before the cutoff) — BR-88 auto-abandon. */
    List<Order> findByStatusAndUpdatedAtBefore(OrderStatus status, LocalDateTime cutoff);

    /** Order history for one branch (UC-54), newest first, with an optional status filter. */
    @Query("select o from Order o where o.store.id = :storeId "
            + "and (:status is null or o.status = :status) order by o.createdAt desc")
    Page<Order> findHistory(@Param("storeId") UUID storeId,
                            @Param("status") OrderStatus status,
                            Pageable pageable);

    /** Sum of order totals for one shift by payment method + status (e.g. CASH + PAID for reconciliation). */
    @Query("select coalesce(sum(o.total), 0) from Order o where o.shiftSession.id = :sessionId "
            + "and o.paymentMethod = :method and o.paymentStatus = :status")
    BigDecimal sumSales(@Param("sessionId") UUID sessionId,
                        @Param("method") PaymentMethod method,
                        @Param("status") PaymentStatus status);
}
