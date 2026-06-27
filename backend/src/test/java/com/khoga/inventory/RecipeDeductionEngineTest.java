package com.khoga.inventory;

import com.khoga.common.model.MenuItem;
import com.khoga.common.model.Order;
import com.khoga.common.model.OrderItem;
import com.khoga.common.model.RawMaterial;
import com.khoga.common.model.RecipeItem;
import com.khoga.common.model.StockItem;
import com.khoga.common.model.Store;
import com.khoga.common.repository.OrderItemRepository;
import com.khoga.common.repository.OrderItemToppingRepository;
import com.khoga.common.repository.RecipeItemRepository;
import com.khoga.common.repository.StockItemRepository;
import com.khoga.common.repository.StockTransactionRepository;
import com.khoga.inventory.dto.DeductionResult;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/** P2.1 unit tests for UC-62 recipe deduction: deduct base recipe, allow negative + phantom usage (BR-89). */
@ExtendWith(MockitoExtension.class)
class RecipeDeductionEngineTest {

    @Mock private OrderItemRepository orderItemRepository;
    @Mock private OrderItemToppingRepository orderItemToppingRepository;
    @Mock private RecipeItemRepository recipeItemRepository;
    @Mock private StockItemRepository stockItemRepository;
    @Mock private StockTransactionRepository stockTransactionRepository;
    @InjectMocks private RecipeDeductionEngine engine;

    private Order order(UUID storeId) {
        Store store = new Store();
        store.setId(storeId);
        Order order = new Order();
        order.setId(UUID.randomUUID());
        order.setStore(store);
        order.setOrderNumber("OD-1");
        return order;
    }

    @Test
    void deductsBaseRecipe_noPhantom_whenEnoughStock() {
        UUID storeId = UUID.randomUUID();
        Order order = order(storeId);

        MenuItem menuItem = new MenuItem();
        menuItem.setId(UUID.randomUUID());
        OrderItem orderItem = new OrderItem();
        orderItem.setId(UUID.randomUUID());
        orderItem.setMenuItem(menuItem);
        orderItem.setQuantity(2);

        RawMaterial mat = new RawMaterial();
        mat.setId(UUID.randomUUID());
        mat.setName("Milk");
        RecipeItem recipe = new RecipeItem();
        recipe.setRawMaterial(mat);
        recipe.setQuantityRequired(new BigDecimal("3"));

        StockItem stock = new StockItem();
        stock.setId(UUID.randomUUID());
        stock.setRawMaterial(mat);
        stock.setCurrentQuantity(new BigDecimal("10"));

        when(orderItemRepository.findByOrderId(order.getId())).thenReturn(List.of(orderItem));
        when(orderItemToppingRepository.findByOrderItemId(orderItem.getId())).thenReturn(List.of());
        when(recipeItemRepository.findByMenuItemId(menuItem.getId())).thenReturn(List.of(recipe));
        when(stockItemRepository.findByStoreIdAndRawMaterialId(storeId, mat.getId())).thenReturn(Optional.of(stock));

        DeductionResult result = engine.deductForOrder(order);

        assertEquals(0, stock.getCurrentQuantity().compareTo(new BigDecimal("4"))); // 10 − 2×3
        assertFalse(result.hasShortage());
        verify(stockTransactionRepository, times(1)).save(any()); // RECIPE_DEDUCTION only
    }

    @Test
    void negativeStock_createsPhantomUsageAndShortage() {
        UUID storeId = UUID.randomUUID();
        Order order = order(storeId);

        MenuItem menuItem = new MenuItem();
        menuItem.setId(UUID.randomUUID());
        OrderItem orderItem = new OrderItem();
        orderItem.setId(UUID.randomUUID());
        orderItem.setMenuItem(menuItem);
        orderItem.setQuantity(2);

        RawMaterial mat = new RawMaterial();
        mat.setId(UUID.randomUUID());
        mat.setName("Espresso Beans");
        RecipeItem recipe = new RecipeItem();
        recipe.setRawMaterial(mat);
        recipe.setQuantityRequired(new BigDecimal("3"));

        StockItem stock = new StockItem();
        stock.setId(UUID.randomUUID());
        stock.setRawMaterial(mat);
        stock.setCurrentQuantity(new BigDecimal("4")); // need 6 → deficit 2

        when(orderItemRepository.findByOrderId(order.getId())).thenReturn(List.of(orderItem));
        when(orderItemToppingRepository.findByOrderItemId(orderItem.getId())).thenReturn(List.of());
        when(recipeItemRepository.findByMenuItemId(menuItem.getId())).thenReturn(List.of(recipe));
        when(stockItemRepository.findByStoreIdAndRawMaterialId(storeId, mat.getId())).thenReturn(Optional.of(stock));

        DeductionResult result = engine.deductForOrder(order);

        assertEquals(0, stock.getCurrentQuantity().compareTo(new BigDecimal("-2")));
        assertTrue(result.hasShortage());
        assertEquals(1, result.shortages().size());
        assertEquals(0, result.shortages().get(0).deficit().compareTo(new BigDecimal("2")));
        verify(stockTransactionRepository, times(2)).save(any()); // RECIPE_DEDUCTION + PHANTOM_USAGE
    }
}
