package com.khoga.common.repository;

import com.khoga.common.model.OptionTopping;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface OptionToppingRepository extends JpaRepository<OptionTopping, UUID> {

    @org.springframework.data.jpa.repository.Query("SELECT m.optionTopping FROM MenuItemToppingMapping m WHERE m.menuItem.id = :menuItemId")
    List<OptionTopping> findByMenuItemId(@org.springframework.data.repository.query.Param("menuItemId") UUID menuItemId);

    /** UC-76 margin report — active toppings (price vs standard-cost COGS). */
    List<OptionTopping> findByIsActiveTrueOrderByName();
}
