package com.khoga.catalog;

import com.khoga.catalog.dto.RecipeLineRequest;
import com.khoga.common.exception.AppException;
import com.khoga.common.model.MenuItem;
import com.khoga.common.model.RawMaterial;
import com.khoga.common.model.RecipeItem;
import com.khoga.common.repository.RawMaterialRepository;
import com.khoga.common.repository.RecipeItemRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/** P1.3 unit tests for BR-73 recipe unit consistency. */
@ExtendWith(MockitoExtension.class)
class RecipeServiceTest {

    @Mock private RecipeItemRepository recipeItemRepository;
    @Mock private RawMaterialRepository rawMaterialRepository;
    @InjectMocks private RecipeService recipeService;

    private MenuItem menuItem() {
        MenuItem item = new MenuItem();
        item.setId(UUID.randomUUID());
        return item;
    }

    private RawMaterial material(String unit, boolean active) {
        RawMaterial rm = new RawMaterial();
        rm.setId(UUID.randomUUID());
        rm.setName("Milk");
        rm.setUnit(unit);
        rm.setIsActive(active);
        return rm;
    }

    @Test
    void unitMismatch_isRejected() {
        when(rawMaterialRepository.findById(any())).thenReturn(Optional.of(material("kg", true)));
        List<RecipeLineRequest> lines = List.of(new RecipeLineRequest(UUID.randomUUID(), new BigDecimal("100"), "g"));

        assertThrows(AppException.class, () -> recipeService.replaceForMenuItem(menuItem(), lines));
        verify(recipeItemRepository, never()).save(any());
    }

    @Test
    void inactiveMaterial_isRejected() {
        when(rawMaterialRepository.findById(any())).thenReturn(Optional.of(material("kg", false)));
        List<RecipeLineRequest> lines = List.of(new RecipeLineRequest(UUID.randomUUID(), new BigDecimal("1"), "kg"));

        assertThrows(AppException.class, () -> recipeService.replaceForMenuItem(menuItem(), lines));
        verify(recipeItemRepository, never()).save(any());
    }

    @Test
    void matchingUnit_savesLine() {
        when(rawMaterialRepository.findById(any())).thenReturn(Optional.of(material("kg", true)));
        List<RecipeLineRequest> lines = List.of(new RecipeLineRequest(UUID.randomUUID(), new BigDecimal("2"), "kg"));

        recipeService.replaceForMenuItem(menuItem(), lines);

        verify(recipeItemRepository).save(any(RecipeItem.class));
    }
}
