package com.khoga.common.repository;

import com.khoga.common.model.StockItem;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface StockItemRepository extends JpaRepository<StockItem, UUID> {

    boolean existsByRawMaterialId(UUID rawMaterialId);

    boolean existsByStoreIdAndRawMaterialId(UUID storeId, UUID rawMaterialId);

    Optional<StockItem> findByStoreIdAndRawMaterialId(UUID storeId, UUID rawMaterialId);

    Page<StockItem> findByStoreId(UUID storeId, Pageable pageable);

    @Query("select s from StockItem s where s.store.id = :storeId and s.currentQuantity <= s.minAlertThreshold")
    Page<StockItem> findLowStockByStore(@Param("storeId") UUID storeId, Pageable pageable);

    @Query("select s from StockItem s where s.store.id = :storeId and s.currentQuantity <= s.minAlertThreshold")
    List<StockItem> findLowStockByStore(@Param("storeId") UUID storeId);

    @Query("select s from StockItem s where s.store.id = :storeId and "
            + "(lower(s.rawMaterial.name) like lower(concat('%', :q, '%')) "
            + "or lower(s.rawMaterial.code) like lower(concat('%', :q, '%')))")
    Page<StockItem> searchByStore(@Param("storeId") UUID storeId, @Param("q") String q, Pageable pageable);
}
