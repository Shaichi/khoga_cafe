package com.khoga.catalog;

import com.khoga.audit.AuditLogService;
import com.khoga.catalog.dto.AvailabilityRequest;
import com.khoga.common.model.MenuItem;
import com.khoga.common.model.Store;
import com.khoga.common.model.User;
import com.khoga.common.model.enums.ActionType;
import com.khoga.common.model.enums.Role;
import com.khoga.common.repository.BranchMenuStatusRepository;
import com.khoga.common.repository.CategoryRepository;
import com.khoga.common.repository.MenuItemRepository;
import com.khoga.common.repository.OptionToppingRepository;
import com.khoga.common.repository.StoreRepository;
import com.khoga.common.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.access.AccessDeniedException;

import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/** P1.3 unit tests: soft delete (BR-28) and per-branch availability scoping (BR-25 / BR-47). */
@ExtendWith(MockitoExtension.class)
class MenuItemServiceTest {

    @Mock private MenuItemRepository menuItemRepository;
    @Mock private CategoryRepository categoryRepository;
    @Mock private OptionToppingRepository optionToppingRepository;
    @Mock private BranchMenuStatusRepository branchMenuStatusRepository;
    @Mock private StoreRepository storeRepository;
    @Mock private UserRepository userRepository;
    @Mock private RecipeService recipeService;
    @Mock private AbbreviationGenerator abbreviationGenerator;
    @Mock private AuditLogService auditLogService;
    @InjectMocks private MenuItemService service;

    @Test
    void softDelete_marksDeletedAndAudits() {
        UUID id = UUID.randomUUID();
        MenuItem item = new MenuItem();
        item.setId(id);
        item.setIsDeleted(false);
        when(menuItemRepository.findById(id)).thenReturn(Optional.of(item));

        service.softDelete(id, UUID.randomUUID());

        assertTrue(item.getIsDeleted());
        verify(menuItemRepository).save(item);
        verify(auditLogService).record(eq(ActionType.DELETE), eq("MenuItem"), any(), any(), any());
    }

    @Test
    void toggleAvailability_storeManagerOtherBranch_throwsAccessDenied() {
        UUID menuItemId = UUID.randomUUID();
        UUID actorId = UUID.randomUUID();
        UUID ownBranch = UUID.randomUUID();
        UUID otherBranch = UUID.randomUUID();

        MenuItem item = new MenuItem();
        item.setId(menuItemId);
        Store own = new Store();
        own.setId(ownBranch);
        User manager = new User();
        manager.setId(actorId);
        manager.setRole(Role.STORE_MANAGER);
        manager.setStore(own);

        when(menuItemRepository.findById(menuItemId)).thenReturn(Optional.of(item));
        when(userRepository.findById(actorId)).thenReturn(Optional.of(manager));

        assertThrows(AccessDeniedException.class, () ->
                service.toggleAvailability(menuItemId, new AvailabilityRequest(otherBranch, true), actorId));
    }
}
