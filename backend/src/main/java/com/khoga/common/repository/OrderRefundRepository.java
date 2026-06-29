package com.khoga.common.repository;

import com.khoga.common.model.OrderRefund;
import com.khoga.common.model.enums.RefundType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface OrderRefundRepository extends JpaRepository<OrderRefund, UUID> {

    /** Sum of cash refunds attached to a shift (BR-09) — reduces the expected drawer at close. */
    @Query("select coalesce(sum(r.amount), 0) from OrderRefund r "
            + "where r.shiftSession.id = :sessionId and r.refundType = :type")
    BigDecimal sumByShiftAndType(@Param("sessionId") UUID sessionId, @Param("type") RefundType type);

    /** UC-81 total refunded amount for one branch in a window, by refund type. */
    @Query("select coalesce(sum(r.amount), 0) from OrderRefund r where r.order.store.id = :storeId "
            + "and r.refundType = :type and r.createdAt >= :from and r.createdAt < :to")
    BigDecimal sumByStoreAndRange(@Param("storeId") UUID storeId, @Param("type") RefundType type,
                                  @Param("from") LocalDateTime from, @Param("to") LocalDateTime to);

    /** UC-81 count of refunds for one branch in a window, by refund type. */
    @Query("select count(r) from OrderRefund r where r.order.store.id = :storeId "
            + "and r.refundType = :type and r.createdAt >= :from and r.createdAt < :to")
    long countByStoreAndRange(@Param("storeId") UUID storeId, @Param("type") RefundType type,
                              @Param("from") LocalDateTime from, @Param("to") LocalDateTime to);

    /** UC-82 per-cashier refund/comp counts in a window (null branch = chain). */
    @Query("select new com.khoga.report.dto.CashierCount(r.cashier.id, count(r)) from OrderRefund r "
            + "where r.refundType = :type and r.createdAt >= :from and r.createdAt < :to "
            + "and (:storeId is null or r.order.store.id = :storeId) group by r.cashier.id")
    List<com.khoga.report.dto.CashierCount> countByCashier(@Param("storeId") UUID storeId,
                                                           @Param("type") RefundType type,
                                                           @Param("from") LocalDateTime from,
                                                           @Param("to") LocalDateTime to);
}
