package com.khoga.inventory;

import com.khoga.common.exception.AppException;
import com.khoga.common.model.RawMaterial;
import com.khoga.common.model.StockItem;
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
import com.khoga.inventory.dto.StockAuditLine;
import com.khoga.inventory.dto.StockAuditRequest;
import com.khoga.inventory.dto.StockAuditResultLine;
import com.khoga.inventory.dto.StockTransactionResponse;
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
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/** P2.1 unit tests for branch stock rules: increment/ledger, branch isolation (BR-59), export guard, audit note (BR-32). */
@ExtendWith(MockitoExtension.class)
class StockServiceTest {

    @Mock private StockItemRepository stockItemRepository;
    @Mock private StockTransactionRepository stockTransactionRepository;
    @Mock private RawMaterialRepository rawMaterialRepository;
    @Mock private UserRepository userRepository;
    @InjectMocks private StockService service;

    private final UUID storeId = UUID.randomUUID();
    private final UUID userId = UUID.randomUUID();

    private User actorInStore(UUID sid) {
        Store store = new Store();
        store.setId(sid);
        User user = new User();
        user.setId(userId);
        user.setStore(store);
        return user;
    }

    private StockItem stockItem(UUID sid, BigDecimal qty) {
        Store store = new Store();
        store.setId(sid);
        RawMaterial mat = new RawMaterial();
        mat.setId(UUID.randomUUID());
        mat.setName("Milk");
        StockItem item = new StockItem();
        item.setId(UUID.randomUUID());
        item.setStore(store);
        item.setRawMaterial(mat);
        item.setCurrentQuantity(qty);
        return item;
    }

    @Test
    void importStock_incrementsAndLogsTransaction() {
        User user = actorInStore(storeId);
        StockItem item = stockItem(storeId, new BigDecimal("5"));
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(stockItemRepository.findByIdForUpdate(item.getId())).thenReturn(Optional.of(item));
        when(stockTransactionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        StockTransactionResponse resp = service.importStock(
                new ImportStockRequest(item.getId(), new BigDecimal("10"), "delivery"), userId);

        assertEquals(0, item.getCurrentQuantity().compareTo(new BigDecimal("15")));
        assertEquals(TransactionType.IMPORT, resp.transactionType());
        assertEquals(0, resp.quantityBefore().compareTo(new BigDecimal("5")));
        assertEquals(0, resp.quantityAfter().compareTo(new BigDecimal("15")));
        verify(stockItemRepository).findByIdForUpdate(item.getId()); // S3.4 pessimistic lock
    }

    @Test
    void importStock_otherBranchItem_throws() {
        User user = actorInStore(storeId);
        StockItem item = stockItem(UUID.randomUUID(), new BigDecimal("5")); // different store
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(stockItemRepository.findByIdForUpdate(item.getId())).thenReturn(Optional.of(item));

        assertThrows(AppException.class, () -> service.importStock(
                new ImportStockRequest(item.getId(), new BigDecimal("10"), "x"), userId));
        verify(stockTransactionRepository, never()).save(any());
    }

    @Test
    void exportStock_insufficient_throws() {
        User user = actorInStore(storeId);
        StockItem item = stockItem(storeId, new BigDecimal("3"));
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(stockItemRepository.findByIdForUpdate(item.getId())).thenReturn(Optional.of(item));

        assertThrows(AppException.class, () -> service.exportStock(
                new ExportStockRequest(item.getId(), new BigDecimal("5"), "wastage"), userId));
        verify(stockItemRepository, never()).save(any());
        verify(stockTransactionRepository, never()).save(any());
    }

    @Test
    void auditStock_discrepancyWithoutNote_throws() {
        User user = actorInStore(storeId);
        StockItem item = stockItem(storeId, new BigDecimal("10"));
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(stockItemRepository.findByIdForUpdate(item.getId())).thenReturn(Optional.of(item));

        StockAuditRequest req = new StockAuditRequest(
                List.of(new StockAuditLine(item.getId(), new BigDecimal("8"), null)));
        assertThrows(AppException.class, () -> service.auditStock(req, userId));
        verify(stockTransactionRepository, never()).save(any());
    }

    @Test
    void auditStock_withNote_adjustsAndReports() {
        User user = actorInStore(storeId);
        StockItem item = stockItem(storeId, new BigDecimal("10"));
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(stockItemRepository.findByIdForUpdate(item.getId())).thenReturn(Optional.of(item));

        StockAuditRequest req = new StockAuditRequest(
                List.of(new StockAuditLine(item.getId(), new BigDecimal("8"), "spillage")));
        List<StockAuditResultLine> result = service.auditStock(req, userId);

        assertEquals(1, result.size());
        assertEquals(0, result.get(0).adjustment().compareTo(new BigDecimal("-2")));
        assertEquals(0, item.getCurrentQuantity().compareTo(new BigDecimal("8")));
        verify(stockTransactionRepository).save(any());
    }

    @Test
    void createStockItem_duplicate_throws() {
        User user = actorInStore(storeId);
        RawMaterial material = new RawMaterial();
        material.setId(UUID.randomUUID());
        material.setIsActive(true);
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(rawMaterialRepository.findById(material.getId())).thenReturn(Optional.of(material));
        when(stockItemRepository.existsByStoreIdAndRawMaterialId(storeId, material.getId())).thenReturn(true);

        assertThrows(AppException.class, () -> service.createStockItem(
                new CreateStockItemRequest(material.getId(), BigDecimal.ZERO), userId));
        verify(stockItemRepository, never()).save(any());
    }
}
