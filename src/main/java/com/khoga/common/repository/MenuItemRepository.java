package com.khoga.common.repository;

import com.khoga.common.model.MenuItem;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface MenuItemRepository extends JpaRepository<MenuItem, UUID> {

    boolean existsByBarcode(String barcode);

    boolean existsByBarcodeAndIdNot(String barcode, UUID id);

    boolean existsByAbbreviation(String abbreviation);

    long countByCategoryIdAndIsActiveTrueAndIsDeletedFalse(UUID categoryId);

    List<MenuItem> findByCategoryId(UUID categoryId);

    Page<MenuItem> findByIsDeletedFalse(Pageable pageable);

    Page<MenuItem> findByIsDeletedFalseAndCategoryId(UUID categoryId, Pageable pageable);

    Page<MenuItem> findByIsDeletedFalseAndNameContainingIgnoreCase(String name, Pageable pageable);
}
