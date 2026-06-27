package com.khoga.inventory;

import com.khoga.common.model.RawMaterial;
import com.khoga.common.model.StockItem;
import com.khoga.common.model.StockTransaction;
import com.khoga.common.model.User;
import com.khoga.inventory.dto.LowStockAlertDto;
import com.khoga.inventory.dto.StockItemResponse;
import com.khoga.inventory.dto.StockTransactionResponse;

/** Hand-written entity → DTO mappers for the inventory feature. */
final class InventoryMapper {

    private InventoryMapper() {
    }

    static boolean isLow(StockItem s) {
        return s.getCurrentQuantity() != null && s.getMinAlertThreshold() != null
                && s.getCurrentQuantity().compareTo(s.getMinAlertThreshold()) <= 0;
    }

    static StockItemResponse toStockItemResponse(StockItem s) {
        RawMaterial m = s.getRawMaterial();
        return new StockItemResponse(
                s.getId(),
                m != null ? m.getId() : null,
                m != null ? m.getCode() : null,
                m != null ? m.getName() : null,
                m != null ? m.getUnit() : null,
                s.getCurrentQuantity(),
                s.getMinAlertThreshold(),
                m != null ? m.getStandardCost() : null,
                isLow(s));
    }

    static StockTransactionResponse toTxResponse(StockTransaction t) {
        StockItem s = t.getStockItem();
        RawMaterial m = s != null ? s.getRawMaterial() : null;
        User mgr = t.getManager();
        return new StockTransactionResponse(
                t.getId(),
                s != null ? s.getId() : null,
                m != null ? m.getName() : null,
                t.getTransactionType(),
                t.getQuantity(),
                t.getQuantityBefore(),
                t.getQuantityAfter(),
                t.getReason(),
                mgr != null ? mgr.getFullName() : null,
                t.getCreatedAt());
    }

    static LowStockAlertDto toLowStockAlert(StockItem s) {
        RawMaterial m = s.getRawMaterial();
        return new LowStockAlertDto(
                s.getId(),
                m != null ? m.getCode() : null,
                m != null ? m.getName() : null,
                s.getCurrentQuantity(),
                s.getMinAlertThreshold());
    }
}
