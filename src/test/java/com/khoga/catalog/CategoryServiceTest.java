package com.khoga.catalog;

import com.khoga.audit.AuditLogService;
import com.khoga.common.exception.AppException;
import com.khoga.common.model.Category;
import com.khoga.common.model.MenuItem;
import com.khoga.common.repository.CategoryRepository;
import com.khoga.common.repository.MenuItemRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/** P1.3 unit tests for category archiving (BR-31 guard + BR-62 unlink). */
@ExtendWith(MockitoExtension.class)
class CategoryServiceTest {

    @Mock private CategoryRepository categoryRepository;
    @Mock private MenuItemRepository menuItemRepository;
    @Mock private AuditLogService auditLogService;
    @InjectMocks private CategoryService categoryService;

    @Test
    void archive_withActiveItems_throws() {
        UUID id = UUID.randomUUID();
        Category category = category(id);
        when(categoryRepository.findById(id)).thenReturn(Optional.of(category));
        when(menuItemRepository.countByCategoryIdAndIsActiveTrueAndIsDeletedFalse(id)).thenReturn(2L);

        assertThrows(AppException.class, () -> categoryService.archive(id, UUID.randomUUID()));
        verify(categoryRepository, never()).save(any());
    }

    @Test
    void archive_empty_unlinksItemsAndDeactivates() {
        UUID id = UUID.randomUUID();
        Category category = category(id);
        MenuItem orphan = new MenuItem();
        orphan.setCategory(category);
        when(categoryRepository.findById(id)).thenReturn(Optional.of(category));
        when(menuItemRepository.countByCategoryIdAndIsActiveTrueAndIsDeletedFalse(id)).thenReturn(0L);
        when(menuItemRepository.findByCategoryId(id)).thenReturn(List.of(orphan));

        categoryService.archive(id, UUID.randomUUID());

        assertNull(orphan.getCategory());                 // BR-62
        assertFalse(category.getIsActive());
        verify(menuItemRepository).saveAll(any());
        verify(categoryRepository).save(category);
    }

    private Category category(UUID id) {
        Category c = new Category();
        c.setId(id);
        c.setName("Coffee");
        c.setIsActive(true);
        return c;
    }
}
