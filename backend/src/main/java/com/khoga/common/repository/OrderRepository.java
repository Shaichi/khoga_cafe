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

    // ----- P3 reporting aggregates (read-only) -----

    /** UC-28 per-branch revenue + completed-order count over a window (COMPLETED orders only). */
    @Query("select new com.khoga.report.dto.BranchRevenueRow(o.store.id, o.store.name, "
            + "coalesce(sum(o.total), 0), count(o)) from Order o "
            + "where o.status = com.khoga.common.model.enums.OrderStatus.COMPLETED "
            + "and o.createdAt >= :from and o.createdAt < :to "
            + "group by o.store.id, o.store.name order by sum(o.total) desc")
    List<com.khoga.report.dto.BranchRevenueRow> revenueByBranch(@Param("from") LocalDateTime from,
                                                                @Param("to") LocalDateTime to);

    /** UC-40 one branch's net revenue (sum total of COMPLETED orders) in a window. */
    @Query("select coalesce(sum(o.total), 0) from Order o where o.store.id = :storeId "
            + "and o.status = com.khoga.common.model.enums.OrderStatus.COMPLETED "
            + "and o.createdAt >= :from and o.createdAt < :to")
    BigDecimal sumStoreRevenue(@Param("storeId") UUID storeId,
                               @Param("from") LocalDateTime from,
                               @Param("to") LocalDateTime to);

    /** UC-40 count of COMPLETED orders for one branch in a window. */
    @Query("select count(o) from Order o where o.store.id = :storeId "
            + "and o.status = com.khoga.common.model.enums.OrderStatus.COMPLETED "
            + "and o.createdAt >= :from and o.createdAt < :to")
    long countStoreCompleted(@Param("storeId") UUID storeId,
                             @Param("from") LocalDateTime from,
                             @Param("to") LocalDateTime to);

    /** UC-40/81 sales collected by tender for one branch (COMPLETED + PAID) in a window. */
    @Query("select coalesce(sum(o.total), 0) from Order o where o.store.id = :storeId "
            + "and o.status = com.khoga.common.model.enums.OrderStatus.COMPLETED "
            + "and o.paymentStatus = com.khoga.common.model.enums.PaymentStatus.PAID "
            + "and o.paymentMethod = :method and o.createdAt >= :from and o.createdAt < :to")
    BigDecimal sumStoreSalesByMethod(@Param("storeId") UUID storeId,
                                     @Param("method") PaymentMethod method,
                                     @Param("from") LocalDateTime from,
                                     @Param("to") LocalDateTime to);

    /** Count of orders in a status created in a window, optionally scoped to a branch (null = chain). */
    @Query("select count(o) from Order o where o.status = :status "
            + "and o.createdAt >= :from and o.createdAt < :to "
            + "and (:storeId is null or o.store.id = :storeId)")
    long countByStatusInRange(@Param("status") OrderStatus status,
                              @Param("storeId") UUID storeId,
                              @Param("from") LocalDateTime from,
                              @Param("to") LocalDateTime to);

    /** Count of all orders created in a window, optionally scoped to a branch (null = chain). */
    @Query("select count(o) from Order o where o.createdAt >= :from and o.createdAt < :to "
            + "and (:storeId is null or o.store.id = :storeId)")
    long countCreatedInRange(@Param("storeId") UUID storeId,
                             @Param("from") LocalDateTime from,
                             @Param("to") LocalDateTime to);

    /** UC-78 loyalty points issued (accrued) on PAID orders in a window (null branch = chain). */
    @Query("select coalesce(sum(o.pointsEarned), 0) from Order o "
            + "where o.paymentStatus = com.khoga.common.model.enums.PaymentStatus.PAID "
            + "and o.createdAt >= :from and o.createdAt < :to "
            + "and (:storeId is null or o.store.id = :storeId)")
    long sumPointsEarned(@Param("storeId") UUID storeId,
                         @Param("from") LocalDateTime from,
                         @Param("to") LocalDateTime to);

    /** UC-78 loyalty points redeemed on PAID orders in a window (null branch = chain). */
    @Query("select coalesce(sum(o.pointsRedeemed), 0) from Order o "
            + "where o.paymentStatus = com.khoga.common.model.enums.PaymentStatus.PAID "
            + "and o.createdAt >= :from and o.createdAt < :to "
            + "and (:storeId is null or o.store.id = :storeId)")
    long sumPointsRedeemed(@Param("storeId") UUID storeId,
                           @Param("from") LocalDateTime from,
                           @Param("to") LocalDateTime to);

    /** UC-79 net sales (sum of COMPLETED order totals) grouped by branch over a window. */
    @Query("select new com.khoga.report.dto.BranchRevenueRow(o.store.id, o.store.name, "
            + "coalesce(sum(o.total), 0), count(o)) from Order o "
            + "where o.status = com.khoga.common.model.enums.OrderStatus.COMPLETED "
            + "and o.createdAt >= :from and o.createdAt < :to "
            + "and (:storeId is null or o.store.id = :storeId) "
            + "group by o.store.id, o.store.name")
    List<com.khoga.report.dto.BranchRevenueRow> netSalesByBranch(@Param("storeId") UUID storeId,
                                                                 @Param("from") LocalDateTime from,
                                                                 @Param("to") LocalDateTime to);

    /** UC-81 summed money + redeemed points for one branch's COMPLETED orders in a window. */
    @Query("select new com.khoga.report.dto.OrderTotalsAccum(coalesce(sum(o.subtotal), 0), "
            + "coalesce(sum(o.discount), 0), coalesce(sum(o.taxAmount), 0), coalesce(sum(o.total), 0), "
            + "coalesce(sum(o.pointsRedeemed), 0)) from Order o where o.store.id = :storeId "
            + "and o.status = com.khoga.common.model.enums.OrderStatus.COMPLETED "
            + "and o.createdAt >= :from and o.createdAt < :to")
    com.khoga.report.dto.OrderTotalsAccum orderTotals(@Param("storeId") UUID storeId,
                                                      @Param("from") LocalDateTime from,
                                                      @Param("to") LocalDateTime to);

    /** UC-82 orders handled per cashier (by the shift's operator) in a window (null branch = chain). */
    @Query("select new com.khoga.report.dto.CashierCount(o.shiftSession.user.id, count(o)) from Order o "
            + "where o.createdAt >= :from and o.createdAt < :to and o.shiftSession.user.id is not null "
            + "and (:storeId is null or o.store.id = :storeId) group by o.shiftSession.user.id")
    List<com.khoga.report.dto.CashierCount> ordersByCashier(@Param("storeId") UUID storeId,
                                                            @Param("from") LocalDateTime from,
                                                            @Param("to") LocalDateTime to);

    /** UC-82 voucher applications per cashier in a window (orders with a voucher; null branch = chain). */
    @Query("select new com.khoga.report.dto.CashierCount(o.shiftSession.user.id, count(o)) from Order o "
            + "where o.voucher is not null and o.createdAt >= :from and o.createdAt < :to "
            + "and o.shiftSession.user.id is not null "
            + "and (:storeId is null or o.store.id = :storeId) group by o.shiftSession.user.id")
    List<com.khoga.report.dto.CashierCount> vouchersByCashier(@Param("storeId") UUID storeId,
                                                              @Param("from") LocalDateTime from,
                                                              @Param("to") LocalDateTime to);
}
