package com.khoga.common.repository;

import com.khoga.common.model.Order;
import com.khoga.common.model.enums.OrderStatus;
import com.khoga.common.model.enums.PaymentMethod;
import com.khoga.common.model.enums.PaymentStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.Collection;
import java.util.List;
import java.util.UUID;

@Repository
public interface OrderRepository extends JpaRepository<Order, UUID> {

    boolean existsByStoreIdAndStatusIn(UUID storeId, Collection<OrderStatus> statuses);

    boolean existsByShiftSessionIdAndStatusIn(UUID shiftSessionId, Collection<OrderStatus> statuses);

    List<Order> findByShiftSessionIdAndStatus(UUID shiftSessionId, OrderStatus status);

    List<Order> findTop50ByCustomerIdOrderByCreatedAtDesc(UUID customerId);

    /** Sum of order totals for one shift by payment method + status (e.g. CASH + PAID for reconciliation). */
    @Query("select coalesce(sum(o.total), 0) from Order o where o.shiftSession.id = :sessionId "
            + "and o.paymentMethod = :method and o.paymentStatus = :status")
    BigDecimal sumSales(@Param("sessionId") UUID sessionId,
                        @Param("method") PaymentMethod method,
                        @Param("status") PaymentStatus status);
}
