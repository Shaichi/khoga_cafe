package com.khoga.catalog;

import com.khoga.audit.AuditLogService;
import com.khoga.catalog.dto.AvailabilityRequest;
import com.khoga.catalog.dto.CreateMenuItemRequest;
import com.khoga.catalog.dto.MenuItemDetailResponse;
import com.khoga.catalog.dto.MenuItemResponse;
import com.khoga.catalog.dto.RecipeLineResponse;
import com.khoga.catalog.dto.ToppingRequest;
import com.khoga.catalog.dto.ToppingResponse;
import com.khoga.catalog.dto.UpdateMenuItemRequest;
import com.khoga.common.exception.AppException;
import com.khoga.common.exception.ResourceNotFoundException;
import com.khoga.common.model.BranchMenuStatus;
import com.khoga.common.model.Category;
import com.khoga.common.model.MenuItem;
import com.khoga.common.model.MenuItemToppingMapping;
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
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/**
 * Menu items + recipes + toppings + per-branch availability (UC-15/18/19/68/71/72). Price changes
 * are audited (BR-68); deletes are soft (BR-28); availability is the per-branch half of the two-level
 * model (BR-25); recipe unit consistency is delegated to {@link RecipeService} (BR-73).
 */
@Service
public class MenuItemService {

    private final MenuItemRepository menuItemRepository;
    private final CategoryRepository categoryRepository;
    private final OptionToppingRepository optionToppingRepository;
    private final MenuItemToppingMappingRepository menuItemToppingMappingRepository;
    private final BranchMenuStatusRepository branchMenuStatusRepository;
    private final StoreRepository storeRepository;
    private final UserRepository userRepository;
    private final RecipeService recipeService;
    private final AbbreviationGenerator abbreviationGenerator;
    private final AuditLogService auditLogService;

    public MenuItemService(MenuItemRepository menuItemRepository, CategoryRepository categoryRepository,
                           OptionToppingRepository optionToppingRepository,
                           MenuItemToppingMappingRepository menuItemToppingMappingRepository,
                           BranchMenuStatusRepository branchMenuStatusRepository, StoreRepository storeRepository,
                           UserRepository userRepository, RecipeService recipeService,
                           AbbreviationGenerator abbreviationGenerator, AuditLogService auditLogService) {
        this.menuItemRepository = menuItemRepository;
        this.categoryRepository = categoryRepository;
        this.optionToppingRepository = optionToppingRepository;
        this.menuItemToppingMappingRepository = menuItemToppingMappingRepository;
        this.branchMenuStatusRepository = branchMenuStatusRepository;
        this.storeRepository = storeRepository;
        this.userRepository = userRepository;
        this.recipeService = recipeService;
        this.abbreviationGenerator = abbreviationGenerator;
        this.auditLogService = auditLogService;
    }

    @Transactional(readOnly = true)
    public Page<MenuItemResponse> list(UUID categoryId, String search, Pageable pageable) {
        Page<MenuItem> page;
        if (StringUtils.hasText(search)) {
            page = menuItemRepository.findByIsDeletedFalseAndNameContainingIgnoreCase(search, pageable);
        } else if (categoryId != null) {
            page = menuItemRepository.findByIsDeletedFalseAndCategoryId(categoryId, pageable);
        } else {
            page = menuItemRepository.findByIsDeletedFalse(pageable);
        }
        return page.map(CatalogMapper::toMenuItemResponse);
    }

    @Transactional(readOnly = true)
    public MenuItemDetailResponse get(UUID id) {
        MenuItem item = load(id);
        return CatalogMapper.toMenuItemDetail(item, recipeService.menuItemRecipe(id), toppingResponses(id));
    }

    @Transactional
    public MenuItemDetailResponse create(CreateMenuItemRequest request, UUID actorId) {
        if (StringUtils.hasText(request.barcode()) && menuItemRepository.existsByBarcode(request.barcode())) {
            throw new AppException("Mã vạch đã tồn tại");
        }
        MenuItem item = new MenuItem();
        item.setName(request.name());
        item.setPrice(request.price());
        item.setDescription(request.description());
        item.setBarcode(request.barcode());
        item.setImageUrl(request.imageUrl());
        item.setCategory(resolveCategory(request.categoryId()));
        item.setIsActive(true);
        item.setIsDeleted(false);
        item.setAbbreviation(abbreviationGenerator.unique(request.name(), menuItemRepository::existsByAbbreviation));
        MenuItem saved = menuItemRepository.save(item);
        recipeService.replaceForMenuItem(saved, request.recipe());            // BR-73
        auditLogService.record(ActionType.CREATE, "MenuItem", null,
                "{\"name\":\"" + request.name() + "\"}", actorId);
        return get(saved.getId());
    }

    @Transactional
    public MenuItemDetailResponse update(UUID id, UpdateMenuItemRequest request, UUID actorId) {
        MenuItem item = load(id);
        if (StringUtils.hasText(request.barcode()) && menuItemRepository.existsByBarcodeAndIdNot(request.barcode(), id)) {
            throw new AppException("Mã vạch đã tồn tại");
        }
        BigDecimal oldPrice = item.getPrice();
        boolean nameChanged = !request.name().equals(item.getName());
        item.setName(request.name());
        item.setPrice(request.price());
        item.setDescription(request.description());
        item.setBarcode(request.barcode());
        item.setImageUrl(request.imageUrl());
        item.setCategory(resolveCategory(request.categoryId()));
        if (nameChanged) {
            item.setAbbreviation(abbreviationGenerator.unique(request.name(), menuItemRepository::existsByAbbreviation));
        }
        menuItemRepository.save(item);
        recipeService.replaceForMenuItem(item, request.recipe());
        if (priceChanged(oldPrice, request.price())) {                          // BR-68
            auditLogService.record(ActionType.UPDATE, "MenuItem",
                    "{\"price\":" + oldPrice + "}", "{\"price\":" + request.price() + "}", actorId);
        } else {
            auditLogService.record(ActionType.UPDATE, "MenuItem", null, "{\"id\":\"" + id + "\"}", actorId);
        }
        return get(id);
    }

    @Transactional
    public void softDelete(UUID id, UUID actorId) {
        MenuItem item = load(id);
        item.setIsDeleted(true);                                                // BR-28
        menuItemRepository.save(item);
        auditLogService.record(ActionType.DELETE, "MenuItem", null, "{\"id\":\"" + id + "\"}", actorId);
    }

    /** UC-19 / BR-25: per-branch availability. A store manager may only toggle their own branch. */
    @Transactional
    public void toggleAvailability(UUID menuItemId, AvailabilityRequest request, UUID actorId) {
        MenuItem item = load(menuItemId);
        User actor = userRepository.findById(actorId)
                .orElseThrow(() -> new AppException("Yêu cầu xác thực"));
        if (actor.getRole() == Role.STORE_MANAGER
                && (actor.getStore() == null || !request.storeId().equals(actor.getStore().getId()))) {
            throw new AccessDeniedException("Chỉ được điều chỉnh chi nhánh của mình");
        }
        Store store = storeRepository.findById(request.storeId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy chi nhánh"));
        BranchMenuStatus status = branchMenuStatusRepository
                .findFirstByStoreIdAndMenuItemId(request.storeId(), menuItemId)
                .orElseGet(() -> {
                    BranchMenuStatus created = new BranchMenuStatus();
                    created.setStore(store);
                    created.setMenuItem(item);
                    return created;
                });
        status.setIsAvailable(request.available());
        branchMenuStatusRepository.save(status);
    }

    @Transactional(readOnly = true)
    public List<ToppingResponse> listToppings(UUID menuItemId) {
        load(menuItemId);
        return toppingResponses(menuItemId);
    }

    @Transactional
    public ToppingResponse addTopping(UUID menuItemId, ToppingRequest request, UUID actorId) {
        MenuItem item = load(menuItemId);
        // Toppings are global; the link to a menu item is a row in menu_item_topping_mappings.
        OptionTopping topping = new OptionTopping();
        topping.setName(request.name());
        topping.setPrice(request.price());
        topping.setIsActive(true);
        OptionTopping saved = optionToppingRepository.save(topping);
        MenuItemToppingMapping mapping = new MenuItemToppingMapping();
        mapping.setMenuItem(item);
        mapping.setOptionTopping(saved);
        menuItemToppingMappingRepository.save(mapping);
        recipeService.replaceForTopping(saved, request.recipe());               // BR-65
        auditLogService.record(ActionType.CREATE, "OptionTopping", null,
                "{\"name\":\"" + request.name() + "\"}", actorId);
        return CatalogMapper.toToppingResponse(saved, recipeService.toppingRecipe(saved.getId()));
    }

    @Transactional
    public ToppingResponse updateTopping(UUID toppingId, ToppingRequest request, UUID actorId) {
        OptionTopping topping = loadTopping(toppingId);
        topping.setName(request.name());
        topping.setPrice(request.price());
        optionToppingRepository.save(topping);
        recipeService.replaceForTopping(topping, request.recipe());
        auditLogService.record(ActionType.UPDATE, "OptionTopping", null, "{\"id\":\"" + toppingId + "\"}", actorId);
        return CatalogMapper.toToppingResponse(topping, recipeService.toppingRecipe(toppingId));
    }

    @Transactional
    public void deactivateTopping(UUID toppingId, UUID actorId) {
        OptionTopping topping = loadTopping(toppingId);
        topping.setIsActive(false);
        optionToppingRepository.save(topping);
        auditLogService.record(ActionType.DELETE, "OptionTopping", null, "{\"id\":\"" + toppingId + "\"}", actorId);
    }

    private boolean priceChanged(BigDecimal oldPrice, BigDecimal newPrice) {
        if (oldPrice == null || newPrice == null) {
            return oldPrice != newPrice;
        }
        return oldPrice.compareTo(newPrice) != 0;
    }

    private List<ToppingResponse> toppingResponses(UUID menuItemId) {
        return optionToppingRepository.findByMenuItemId(menuItemId).stream()
                .map(t -> CatalogMapper.toToppingResponse(t, recipeService.toppingRecipe(t.getId())))
                .toList();
    }

    private Category resolveCategory(UUID categoryId) {
        if (categoryId == null) {
            return null;
        }
        return categoryRepository.findById(categoryId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy danh mục"));
    }

    private MenuItem load(UUID id) {
        return menuItemRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy món"));
    }

    private OptionTopping loadTopping(UUID id) {
        return optionToppingRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy topping"));
    }
}
