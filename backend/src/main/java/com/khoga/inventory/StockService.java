package com.khoga.inventory;

import com.khoga.common.exception.AppException;
import com.khoga.common.exception.ResourceNotFoundException;
import com.khoga.common.model.RawMaterial;
import com.khoga.common.model.StockItem;
import com.khoga.common.model.StockTransaction;
import com.khoga.common.model.Store;
import com.khoga.common.model.User;
import com.khoga.common.model.enums.TransactionType;
import com.khoga.common.repository.RawMaterialRepository;
import com.khoga.common.repository.StockItemRepository;
import com.khoga.common.repository.StockTransactionRepository;
import com.khoga.common.repository.UserRepository;
import com.khoga.inventory.dto.CreateStockItemRequest;
import com.khoga.inventory.dto.ExportStockRequest;
import com.khoga.inventory.dto.ImportStockRequest;
import com.khoga.inventory.dto.LowStockAlertDto;
import com.khoga.inventory.dto.StockAuditLine;
import com.khoga.inventory.dto.StockAuditRequest;
import com.khoga.inventory.dto.StockAuditResultLine;
import com.khoga.inventory.dto.StockItemResponse;
import com.khoga.inventory.dto.StockTransactionResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Branch inventory operations (UC-31/32/33/34/61). Every operation is scoped to the acting Store
 * Manager's own branch (BR-59); a stock item belonging to another branch is rejected. Each movement
 * writes a {@link StockTransaction} with a before/after snapshot for the audit ledger.
 */
@Service
public class StockService {

    private final StockItemRepository stockItemRepository;
    private final StockTransactionRepository stockTransactionRepository;
    private final RawMaterialRepository rawMaterialRepository;
    private final UserRepository userRepository;

    public StockService(StockItemRepository stockItemRepository,
                        StockTransactionRepository stockTransactionRepository,
                        RawMaterialRepository rawMaterialRepository,
                        UserRepository userRepository) {
        this.stockItemRepository = stockItemRepository;
        this.stockTransactionRepository = stockTransactionRepository;
        this.rawMaterialRepository = rawMaterialRepository;
        this.userRepository = userRepository;
    }

    /** UC-31 — branch stock list, optional low-stock filter or name/code search. */
    @Transactional(readOnly = true)
    public Page<StockItemResponse> list(Boolean lowStock, String search, UUID actorId, Pageable pageable) {
        UUID storeId = currentStore(actorId).getId();
        Page<StockItem> page;
        if (StringUtils.hasText(search)) {
            page = stockItemRepository.searchByStore(storeId, search, pageable);
        } else if (Boolean.TRUE.equals(lowStock)) {
            page = stockItemRepository.findLowStockByStore(storeId, pageable);
        } else {
            page = stockItemRepository.findByStoreId(storeId, pageable);
        }
        return page.map(InventoryMapper::toStockItemResponse);
    }

    /** Provision a chain-wide raw material into this branch's stock (starts at 0). */
    @Transactional
    public StockItemResponse createStockItem(CreateStockItemRequest req, UUID actorId) {
        Store store = currentStore(actorId);
        RawMaterial material = rawMaterialRepository.findById(req.rawMaterialId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy nguyên liệu"));
        if (Boolean.FALSE.equals(material.getIsActive())) {
            throw AppException.of("err.029");
        }
        if (stockItemRepository.existsByStoreIdAndRawMaterialId(store.getId(), material.getId())) {
            throw AppException.of("err.030");
        }
        StockItem item = new StockItem();
        item.setStore(store);
        item.setRawMaterial(material);
        item.setCurrentQuantity(BigDecimal.ZERO);
        item.setMinAlertThreshold(req.minAlertThreshold());
        return InventoryMapper.toStockItemResponse(stockItemRepository.save(item));
    }

    /** UC-32 — import (increment) with an IMPORT ledger entry. */
    @Transactional
    public StockTransactionResponse importStock(ImportStockRequest req, UUID actorId) {
        User user = currentUser(actorId);
        StockItem item = loadForStore(req.stockItemId(), user.getStore());
        BigDecimal before = nz(item.getCurrentQuantity());
        BigDecimal after = before.add(req.quantity());
        item.setCurrentQuantity(after);
        stockItemRepository.save(item);
        return InventoryMapper.toTxResponse(
                record(item, TransactionType.IMPORT, req.quantity(), before, after, user, req.note()));
    }

    /** UC-33 — export/withdraw (decrement, never below zero for manual export) with reason. */
    @Transactional
    public StockTransactionResponse exportStock(ExportStockRequest req, UUID actorId) {
        User user = currentUser(actorId);
        StockItem item = loadForStore(req.stockItemId(), user.getStore());
        BigDecimal before = nz(item.getCurrentQuantity());
        BigDecimal after = before.subtract(req.quantity());
        if (after.signum() < 0) {
            throw new AppException("Không đủ tồn để xuất (hiện có " + before.toPlainString() + ")");
        }
        item.setCurrentQuantity(after);
        stockItemRepository.save(item);
        return InventoryMapper.toTxResponse(
                record(item, TransactionType.EXPORT, req.quantity().negate(), before, after, user, req.reason()));
    }

    /** UC-34 — physical count; mandatory note on any discrepancy (BR-32). */
    @Transactional
    public List<StockAuditResultLine> auditStock(StockAuditRequest req, UUID actorId) {
        User user = currentUser(actorId);
        List<StockAuditResultLine> results = new ArrayList<>();
        for (StockAuditLine line : req.items()) {
            StockItem item = loadForStore(line.stockItemId(), user.getStore());
            BigDecimal before = nz(item.getCurrentQuantity());
            BigDecimal after = line.actualQuantity();
            BigDecimal adjustment = after.subtract(before);
            if (adjustment.signum() != 0 && !StringUtils.hasText(line.note())) {
                throw AppException.of("err.031");
            }
            item.setCurrentQuantity(after);
            stockItemRepository.save(item);
            record(item, TransactionType.AUDIT_ADJUSTMENT, adjustment, before, after, user, line.note());
            String name = item.getRawMaterial() != null ? item.getRawMaterial().getName() : null;
            results.add(new StockAuditResultLine(item.getId(), name, before, after, adjustment));
        }
        return results;
    }

    /** UC-61 — branch stock movement ledger with optional type/date filters. */
    @Transactional(readOnly = true)
    public Page<StockTransactionResponse> history(TransactionType type, LocalDateTime from, LocalDateTime to,
                                                  UUID actorId, Pageable pageable) {
        UUID storeId = currentStore(actorId).getId();
        return stockTransactionRepository.findHistory(storeId, type, from, to, pageable)
                .map(InventoryMapper::toTxResponse);
    }

    /** Low-stock items for a given store — used by {@code LowStockAlertScheduler} (no security context). */
    @Transactional(readOnly = true)
    public List<LowStockAlertDto> checkLowStock(UUID storeId) {
        return stockItemRepository.findLowStockByStore(storeId).stream()
                .map(InventoryMapper::toLowStockAlert)
                .toList();
    }

    private StockTransaction record(StockItem item, TransactionType type, BigDecimal change,
                                    BigDecimal before, BigDecimal after, User manager, String reason) {
        StockTransaction tx = new StockTransaction();
        tx.setStockItem(item);
        tx.setManager(manager);
        tx.setTransactionType(type);
        tx.setQuantity(change);
        tx.setQuantityBefore(before);
        tx.setQuantityAfter(after);
        tx.setReason(reason);
        return stockTransactionRepository.save(tx);
    }

    private StockItem loadForStore(UUID stockItemId, Store store) {
        // S3.4: pessimistic-write lock so concurrent import/export/audit can't lose an update.
        StockItem item = stockItemRepository.findByIdForUpdate(stockItemId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy mục tồn kho"));
        if (item.getStore() == null || !item.getStore().getId().equals(store.getId())) {
            throw AppException.of("err.032"); // BR-59
        }
        return item;
    }

    private User currentUser(UUID actorId) {
        User user = userRepository.findById(actorId)
                .orElseThrow(() -> AppException.of("err.033"));
        if (user.getStore() == null) {
            throw AppException.of("err.034");
        }
        return user;
    }

    private Store currentStore(UUID actorId) {
        return currentUser(actorId).getStore();
    }

    private static BigDecimal nz(BigDecimal v) {
        return v == null ? BigDecimal.ZERO : v;
    }
}
