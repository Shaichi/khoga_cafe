package com.khoga.catalog;

import com.khoga.audit.AuditLogService;
import com.khoga.catalog.dto.CreateRawMaterialRequest;
import com.khoga.catalog.dto.UpdateRawMaterialRequest;
import com.khoga.common.exception.AppException;
import com.khoga.common.model.RawMaterial;
import com.khoga.common.repository.RawMaterialRepository;
import com.khoga.common.repository.RecipeItemRepository;
import com.khoga.common.repository.StockItemRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/** P1.3 unit tests for raw-material rules: unique code, BR-64 unit lock. */
@ExtendWith(MockitoExtension.class)
class RawMaterialServiceTest {

    @Mock private RawMaterialRepository rawMaterialRepository;
    @Mock private StockItemRepository stockItemRepository;
    @Mock private RecipeItemRepository recipeItemRepository;
    @Mock private AuditLogService auditLogService;
    @InjectMocks private RawMaterialService service;

    @Test
    void create_duplicateCode_throws() {
        when(rawMaterialRepository.existsByCodeIgnoreCase("MILK")).thenReturn(true);

        assertThrows(AppException.class, () -> service.create(
                new CreateRawMaterialRequest("MILK", "Milk", "kg", null, null, "Dairy"), UUID.randomUUID()));
        verify(rawMaterialRepository, never()).save(any());
    }

    @Test
    void update_unitChangeWhenLocked_throws() {
        UUID id = UUID.randomUUID();
        RawMaterial material = new RawMaterial();
        material.setId(id);
        material.setUnit("kg");
        when(rawMaterialRepository.findById(id)).thenReturn(Optional.of(material));
        when(stockItemRepository.existsByRawMaterialId(id)).thenReturn(true);   // locked (BR-64)

        assertThrows(AppException.class, () -> service.update(id,
                new UpdateRawMaterialRequest("Milk", "g", null, null, "Dairy", true), UUID.randomUUID()));
        verify(rawMaterialRepository, never()).save(any());
    }

    @Test
    void update_sameUnit_isAllowedEvenWhenInUse() {
        UUID id = UUID.randomUUID();
        RawMaterial material = new RawMaterial();
        material.setId(id);
        material.setUnit("kg");
        when(rawMaterialRepository.findById(id)).thenReturn(Optional.of(material));

        service.update(id, new UpdateRawMaterialRequest("Milk Powder", "kg", null, null, "Dairy", true),
                UUID.randomUUID());

        verify(rawMaterialRepository).save(material);
    }
}
