package com.khoga.common.repository;

import com.khoga.common.model.MenuItemToppingMapping;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface MenuItemToppingMappingRepository extends JpaRepository<MenuItemToppingMapping, UUID> {

    List<MenuItemToppingMapping> findByMenuItemId(UUID menuItemId);

    boolean existsByMenuItemIdAndOptionToppingId(UUID menuItemId, UUID optionToppingId);
}
