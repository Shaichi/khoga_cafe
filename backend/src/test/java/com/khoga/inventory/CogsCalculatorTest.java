package com.khoga.inventory;

import com.khoga.common.model.RawMaterial;
import com.khoga.common.model.RecipeItem;
import com.khoga.common.repository.RecipeItemRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.when;

/** P2.1 unit test for BR-66 standard-cost COGS: Σ(recipe qty × standardCost). */
@ExtendWith(MockitoExtension.class)
class CogsCalculatorTest {

    @Mock private RecipeItemRepository recipeItemRepository;
    @InjectMocks private CogsCalculator calculator;

    @Test
    void menuItemUnitCost_sumsQuantityTimesStandardCost() {
        UUID menuItemId = UUID.randomUUID();

        RawMaterial milk = new RawMaterial();
        milk.setStandardCost(new BigDecimal("1500"));
        RecipeItem line1 = new RecipeItem();
        line1.setRawMaterial(milk);
        line1.setQuantityRequired(new BigDecimal("2")); // 3000

        RawMaterial beans = new RawMaterial();
        beans.setStandardCost(new BigDecimal("1000"));
        RecipeItem line2 = new RecipeItem();
        line2.setRawMaterial(beans);
        line2.setQuantityRequired(new BigDecimal("3")); // 3000

        when(recipeItemRepository.findByMenuItemId(menuItemId)).thenReturn(List.of(line1, line2));

        assertEquals(0, calculator.menuItemUnitCost(menuItemId).compareTo(new BigDecimal("6000")));
    }
}
