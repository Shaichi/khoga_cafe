package com.khoga.inventory;

import com.khoga.common.model.RecipeItem;
import com.khoga.common.repository.RecipeItemRepository;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/**
 * BR-66 standard-cost COGS engine: the cost of one menu item / topping is the sum over its recipe of
 * {@code quantityRequired × rawMaterial.standardCost} (per master unit). Used by the COGS / margin /
 * shrinkage reports (UC-76, P3).
 */
@Component
public class CogsCalculator {

    private final RecipeItemRepository recipeItemRepository;

    public CogsCalculator(RecipeItemRepository recipeItemRepository) {
        this.recipeItemRepository = recipeItemRepository;
    }

    public BigDecimal menuItemUnitCost(UUID menuItemId) {
        return sum(recipeItemRepository.findByMenuItemId(menuItemId));
    }

    public BigDecimal toppingUnitCost(UUID optionToppingId) {
        return sum(recipeItemRepository.findByOptionToppingId(optionToppingId));
    }

    private BigDecimal sum(List<RecipeItem> lines) {
        BigDecimal total = BigDecimal.ZERO;
        for (RecipeItem ri : lines) {
            if (ri.getQuantityRequired() == null || ri.getRawMaterial() == null
                    || ri.getRawMaterial().getStandardCost() == null) {
                continue;
            }
            total = total.add(ri.getQuantityRequired().multiply(ri.getRawMaterial().getStandardCost()));
        }
        return total;
    }
}
