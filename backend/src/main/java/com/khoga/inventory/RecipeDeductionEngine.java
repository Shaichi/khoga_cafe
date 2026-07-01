package com.khoga.inventory;

import com.khoga.common.model.Order;
import com.khoga.common.model.OrderItem;
import com.khoga.common.model.OrderItemTopping;
import com.khoga.common.model.RecipeItem;
import com.khoga.common.model.StockItem;
import com.khoga.common.model.StockTransaction;
import com.khoga.common.model.enums.TransactionType;
import com.khoga.common.repository.OrderItemRepository;
import com.khoga.common.repository.OrderItemToppingRepository;
import com.khoga.common.repository.RecipeItemRepository;
import com.khoga.common.repository.StockItemRepository;
import com.khoga.common.repository.StockTransactionRepository;
import com.khoga.inventory.dto.DeductionResult;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * UC-62 — automatic stock deduction when an order moves {@code PENDING → PREPARING}. Consumes the
 * recipe of the base menu item AND every selected topping (BR-65). Stock is allowed to go negative;
 * the shortfall is logged as a {@code PHANTOM_USAGE} transaction (BR-89). Cancellation only happens in
 * PENDING (before any deduction), so there is no replenishment on cancel (BR-07). System deductions
 * carry a null manager to distinguish them from manual adjustments. Invoked by the Order subsystem (P2.3).
 */
@Slf4j
@Component
public class RecipeDeductionEngine {

    private final OrderItemRepository orderItemRepository;
    private final OrderItemToppingRepository orderItemToppingRepository;
    private final RecipeItemRepository recipeItemRepository;
    private final StockItemRepository stockItemRepository;
    private final StockTransactionRepository stockTransactionRepository;

    public RecipeDeductionEngine(OrderItemRepository orderItemRepository,
                                 OrderItemToppingRepository orderItemToppingRepository,
                                 RecipeItemRepository recipeItemRepository,
                                 StockItemRepository stockItemRepository,
                                 StockTransactionRepository stockTransactionRepository) {
        this.orderItemRepository = orderItemRepository;
        this.orderItemToppingRepository = orderItemToppingRepository;
        this.recipeItemRepository = recipeItemRepository;
        this.stockItemRepository = stockItemRepository;
        this.stockTransactionRepository = stockTransactionRepository;
    }

    @Transactional
    public DeductionResult deductForOrder(Order order) {
        UUID storeId = order.getStore().getId();
        Map<UUID, BigDecimal> required = new LinkedHashMap<>();

        for (OrderItem item : orderItemRepository.findByOrderId(order.getId())) {
            int itemQty = item.getQuantity() == null ? 1 : item.getQuantity();
            if (item.getMenuItem() != null) {
                for (RecipeItem ri : recipeItemRepository.findByMenuItemId(item.getMenuItem().getId())) {
                    accumulate(required, ri, itemQty);
                }
            }
            for (OrderItemTopping topping : orderItemToppingRepository.findByOrderItemId(item.getId())) {
                int toppingQty = topping.getQuantity() == null ? 1 : topping.getQuantity();
                if (topping.getTopping() != null) {
                    for (RecipeItem ri : recipeItemRepository.findByOptionToppingId(topping.getTopping().getId())) {
                        accumulate(required, ri, itemQty * toppingQty);
                    }
                }
            }
        }

        List<DeductionResult.Shortage> shortages = new ArrayList<>();
        for (Map.Entry<UUID, BigDecimal> entry : required.entrySet()) {
            UUID materialId = entry.getKey();
            BigDecimal need = entry.getValue();
            // S3.4: lock the branch stock row for the read-modify-write (concurrent deductions).
            StockItem stock = stockItemRepository.findByStoreIdAndRawMaterialIdForUpdate(storeId, materialId).orElse(null);
            if (stock == null) {
                shortages.add(new DeductionResult.Shortage(null, materialId.toString(), need));
                log.warn("[MSG07] No branch stock row for material {} at store {} — phantom {}", materialId, storeId, need);
                continue;
            }
            BigDecimal before = nz(stock.getCurrentQuantity());
            BigDecimal after = before.subtract(need);
            stock.setCurrentQuantity(after);
            stockItemRepository.save(stock);
            record(stock, TransactionType.RECIPE_DEDUCTION, need.negate(), before, after,
                    "Auto-deduction order " + order.getOrderNumber());
            if (after.signum() < 0) {
                BigDecimal deficit = after.abs();
                record(stock, TransactionType.PHANTOM_USAGE, deficit, after, after,
                        "Phantom usage (insufficient stock) order " + order.getOrderNumber());
                String name = stock.getRawMaterial() != null ? stock.getRawMaterial().getName() : materialId.toString();
                shortages.add(new DeductionResult.Shortage(stock.getId(), name, deficit));
                log.warn("[MSG07] Negative stock for {} at store {} (deficit {})", name, storeId, deficit);
            }
        }
        return new DeductionResult(shortages);
    }

    private void accumulate(Map<UUID, BigDecimal> required, RecipeItem ri, int multiplier) {
        if (ri.getRawMaterial() == null || ri.getQuantityRequired() == null) {
            return;
        }
        required.merge(ri.getRawMaterial().getId(),
                ri.getQuantityRequired().multiply(BigDecimal.valueOf(multiplier)),
                BigDecimal::add);
    }

    private void record(StockItem item, TransactionType type, BigDecimal change,
                        BigDecimal before, BigDecimal after, String reason) {
        StockTransaction tx = new StockTransaction();
        tx.setStockItem(item);
        tx.setManager(null);
        tx.setTransactionType(type);
        tx.setQuantity(change);
        tx.setQuantityBefore(before);
        tx.setQuantityAfter(after);
        tx.setReason(reason);
        stockTransactionRepository.save(tx);
    }

    private static BigDecimal nz(BigDecimal v) {
        return v == null ? BigDecimal.ZERO : v;
    }
}
