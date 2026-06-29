package com.khoga.common.repository;

import com.khoga.common.model.StockTransaction;
import com.khoga.common.model.enums.TransactionType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface StockTransactionRepository extends JpaRepository<StockTransaction, UUID> {

    /** Branch-scoped ledger (UC-61) with optional type / date-range filters. */
    @Query("select t from StockTransaction t where t.stockItem.store.id = :storeId "
            + "and (:type is null or t.transactionType = :type) "
            + "and (:from is null or t.createdAt >= :from) "
            + "and (:to is null or t.createdAt <= :to) "
            + "order by t.createdAt desc")
    Page<StockTransaction> findHistory(@Param("storeId") UUID storeId,
                                       @Param("type") TransactionType type,
                                       @Param("from") LocalDateTime from,
                                       @Param("to") LocalDateTime to,
                                       Pageable pageable);

    /**
     * UC-76 shrinkage basis — total movement quantity per raw material per transaction type over a
     * window, optionally branch-scoped (null = chain). The service folds these into theoretical
     * (RECIPE_DEDUCTION + PHANTOM_USAGE) vs audited (AUDIT_ADJUSTMENT) usage.
     */
    @Query("select new com.khoga.report.dto.StockUsageAccum(rm.id, rm.name, rm.unit, rm.standardCost, "
            + "t.transactionType, coalesce(sum(t.quantity), 0)) from StockTransaction t "
            + "join t.stockItem si join si.rawMaterial rm "
            + "where t.transactionType in (com.khoga.common.model.enums.TransactionType.RECIPE_DEDUCTION, "
            + "com.khoga.common.model.enums.TransactionType.PHANTOM_USAGE, "
            + "com.khoga.common.model.enums.TransactionType.AUDIT_ADJUSTMENT) "
            + "and t.createdAt >= :from and t.createdAt < :to "
            + "and (:storeId is null or si.store.id = :storeId) "
            + "group by rm.id, rm.name, rm.unit, rm.standardCost, t.transactionType")
    List<com.khoga.report.dto.StockUsageAccum> usageByMaterialAndType(@Param("storeId") UUID storeId,
                                                                      @Param("from") LocalDateTime from,
                                                                      @Param("to") LocalDateTime to);
}
