package com.khoga.common.repository;

import com.khoga.common.model.RecipeItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface RecipeItemRepository extends JpaRepository<RecipeItem, UUID> {

    List<RecipeItem> findByMenuItemId(UUID menuItemId);

    List<RecipeItem> findByOptionToppingId(UUID optionToppingId);

    boolean existsByRawMaterialId(UUID rawMaterialId);

    void deleteByMenuItemId(UUID menuItemId);

    void deleteByOptionToppingId(UUID optionToppingId);
}
