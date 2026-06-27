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
}
