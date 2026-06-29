package com.khoga.common.repository;

import com.khoga.common.model.OrderCancellation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface OrderCancellationRepository extends JpaRepository<OrderCancellation, UUID> {

    /** UC-81 count of PENDING cancellations for one branch in a window (BR-51). */
    @Query("select count(c) from OrderCancellation c where c.order.store.id = :storeId "
            + "and c.createdAt >= :from and c.createdAt < :to")
    long countByStoreAndRange(@Param("storeId") UUID storeId,
                              @Param("from") LocalDateTime from, @Param("to") LocalDateTime to);

    /** UC-82 per-cashier cancellation counts in a window (null branch = chain). */
    @Query("select new com.khoga.report.dto.CashierCount(c.cashier.id, count(c)) from OrderCancellation c "
            + "where c.createdAt >= :from and c.createdAt < :to "
            + "and (:storeId is null or c.order.store.id = :storeId) group by c.cashier.id")
    List<com.khoga.report.dto.CashierCount> countByCashier(@Param("storeId") UUID storeId,
                                                           @Param("from") LocalDateTime from,
                                                           @Param("to") LocalDateTime to);
}
