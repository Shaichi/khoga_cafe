package com.khoga.common.repository;

import com.khoga.common.model.StockItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface StockItemRepository extends JpaRepository<StockItem, UUID> {

    boolean existsByRawMaterialId(UUID rawMaterialId);
}
