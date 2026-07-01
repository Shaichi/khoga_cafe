package com.khoga.catalog;

import com.khoga.audit.AuditLogService;
import com.khoga.catalog.dto.AvailabilityRequest;
import com.khoga.catalog.dto.CreateMenuItemRequest;
import com.khoga.catalog.dto.MenuItemResponse;
import com.khoga.catalog.dto.MenuItemVariantRequest;
import com.khoga.catalog.dto.ToppingRequest;
import com.khoga.common.model.BranchMenuStatus;
import com.khoga.common.model.MenuItem;
import com.khoga.common.model.OptionTopping;
import com.khoga.common.model.Store;
import com.khoga.common.model.User;
import com.khoga.common.model.enums.ActionType;
import com.khoga.common.model.enums.Role;
import com.khoga.common.repository.BranchMenuStatusRepository;
import com.khoga.common.repository.CategoryRepository;
import com.khoga.common.repository.MenuItemRepository;
import com.khoga.common.repository.MenuItemToppingMappingRepository;
import com.khoga.common.repository.OptionToppingRepository;
import com.khoga.common.repository.StoreRepository;
import com.khoga.common.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.access.AccessDeniedException;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/** P1.3 unit tests: soft delete (BR-28) and per-branch availability scoping (BR-25 / BR-47). */
@ExtendWith(MockitoExtension.class)
class MenuItemServiceTest {

    @Mock private MenuItemRepository menuItemRepository;
    @Mock private CategoryRepository categoryRepository;
    @Mock private OptionToppingRepository optionToppingRepository;
    @Mock private MenuItemToppingMappingRepository menuItemToppingMappingRepository;
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
    void create_withSizeVariants_createsChildItemsPointingAtBase() {
        UUID baseId = UUID.randomUUID();
        when(abbreviationGenerator.unique(any(), any())).thenReturn("abc");
        when(menuItemRepository.save(any(MenuItem.class))).thenAnswer(inv -> {
            MenuItem m = inv.getArgument(0);
            if (m.getId() == null) {
                m.setId(m.getParentItemId() == null ? baseId : UUID.randomUUID());
            }
            return m;
        });
        MenuItem base = new MenuItem();
        base.setId(baseId);
        when(menuItemRepository.findById(baseId)).thenReturn(Optional.of(base));
        when(recipeService.menuItemRecipe(baseId)).thenReturn(List.of());
        when(optionToppingRepository.findByMenuItemId(baseId)).thenReturn(List.of());

        CreateMenuItemRequest request = new CreateMenuItemRequest(
                "Trà đào", new BigDecimal("30000"), null, null, null, null, null,
                List.of(new MenuItemVariantRequest("S", "TD-S", new BigDecimal("25000")),
                        new MenuItemVariantRequest("M", "TD-M", new BigDecimal("30000")),
                        new MenuItemVariantRequest("L", "TD-L", new BigDecimal("35000"))));

        service.create(request, UUID.randomUUID());

        ArgumentCaptor<MenuItem> captor = ArgumentCaptor.forClass(MenuItem.class);
        verify(menuItemRepository, org.mockito.Mockito.atLeast(4)).save(captor.capture());
        List<MenuItem> variants = captor.getAllValues().stream()
                .filter(m -> m.getParentItemId() != null).toList();
        assertEquals(3, variants.size());
        assertTrue(variants.stream().allMatch(v -> baseId.equals(v.getParentItemId())));
        assertTrue(variants.stream().anyMatch(v -> "S".equals(v.getSizeName())
                && "TD-S".equals(v.getSku()) && new BigDecimal("25000").compareTo(v.getPrice()) == 0));
        assertTrue(variants.stream().anyMatch(v -> "L".equals(v.getSizeName())
                && new BigDecimal("35000").compareTo(v.getPrice()) == 0));
    }

    @Test
    void list_withStore_marksBranchToggledItemsOutOfStock() {
        UUID storeId = UUID.randomUUID();
        UUID itemAId = UUID.randomUUID();
        UUID itemBId = UUID.randomUUID();
        MenuItem a = new MenuItem();
        a.setId(itemAId);
        a.setIsActive(true);
        a.setIsDeleted(false);
        MenuItem b = new MenuItem();
        b.setId(itemBId);
        b.setIsActive(true);
        b.setIsDeleted(false);
        Pageable pageable = PageRequest.of(0, 20);
        // storeId present → active-only query (chain-inactive items already excluded here, BR-25).
        when(menuItemRepository.findByIsDeletedFalseAndIsActiveTrue(pageable))
                .thenReturn(new PageImpl<>(List.of(a, b), pageable, 2));
        BranchMenuStatus offA = new BranchMenuStatus();
        offA.setMenuItem(a);
        offA.setIsAvailable(false);
        when(branchMenuStatusRepository.findByStoreIdAndMenuItemIdIn(eq(storeId), any()))
                .thenReturn(List.of(offA));

        Page<MenuItemResponse> page = service.list(storeId, null, null, pageable);

        Map<UUID, Boolean> available = page.getContent().stream()
                .collect(Collectors.toMap(MenuItemResponse::id, MenuItemResponse::available));
        assertFalse(available.get(itemAId), "branch toggled off → Out of Stock");
        assertTrue(available.get(itemBId), "no branch row → available by default");
    }

    @Test
    void addTopping_withMultipleMenuItemIds_createsOneToppingReusedAcrossItems() {
        UUID id1 = UUID.randomUUID();
        UUID id2 = UUID.randomUUID();
        UUID id3 = UUID.randomUUID();
        for (UUID id : List.of(id1, id2, id3)) {
            MenuItem m = new MenuItem();
            m.setId(id);
            when(menuItemRepository.findById(id)).thenReturn(Optional.of(m));
        }
        OptionTopping saved = new OptionTopping();
        saved.setId(UUID.randomUUID());
        when(optionToppingRepository.save(any())).thenReturn(saved);
        when(recipeService.toppingRecipe(any())).thenReturn(List.of());

        ToppingRequest request = new ToppingRequest(
                "Trân châu", new BigDecimal("5000"), null, List.of(id2, id3));

        service.addTopping(id1, request, UUID.randomUUID());

        verify(optionToppingRepository, times(1)).save(any());            // one global topping, not cloned
        verify(menuItemToppingMappingRepository, times(3)).save(any());   // linked to all three items
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
