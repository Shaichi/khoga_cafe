package com.khoga.catalog;

import com.khoga.audit.AuditLogService;
import com.khoga.catalog.dto.CategoryRequest;
import com.khoga.catalog.dto.CategoryResponse;
import com.khoga.common.exception.AppException;
import com.khoga.common.exception.ResourceNotFoundException;
import com.khoga.common.model.Category;
import com.khoga.common.model.MenuItem;
import com.khoga.common.model.enums.ActionType;
import com.khoga.common.repository.CategoryRepository;
import com.khoga.common.repository.MenuItemRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/** Category management (UC-16/17/69/70). Archiving is guarded (BR-31) and unlinks items (BR-62). */
@Service
public class CategoryService {

    private final CategoryRepository categoryRepository;
    private final MenuItemRepository menuItemRepository;
    private final AuditLogService auditLogService;

    public CategoryService(CategoryRepository categoryRepository, MenuItemRepository menuItemRepository,
                           AuditLogService auditLogService) {
        this.categoryRepository = categoryRepository;
        this.menuItemRepository = menuItemRepository;
        this.auditLogService = auditLogService;
    }

    @Transactional(readOnly = true)
    public Page<CategoryResponse> list(Boolean active, Pageable pageable) {
        Page<Category> page = (active == null)
                ? categoryRepository.findAll(pageable)
                : categoryRepository.findByIsActive(active, pageable);
        return page.map(CatalogMapper::toCategoryResponse);
    }

    @Transactional
    public CategoryResponse create(CategoryRequest request, UUID actorId) {
        if (categoryRepository.existsByNameIgnoreCase(request.name())) {
            throw new AppException("Tên danh mục đã tồn tại");
        }
        Category category = new Category();
        category.setName(request.name());
        category.setDescription(request.description());
        category.setIsActive(true);
        Category saved = categoryRepository.save(category);
        auditLogService.record(ActionType.CREATE, "Category", null,
                "{\"name\":\"" + request.name() + "\"}", actorId);
        return CatalogMapper.toCategoryResponse(saved);
    }

    @Transactional
    public CategoryResponse update(UUID id, CategoryRequest request, UUID actorId) {
        Category category = load(id);
        if (categoryRepository.existsByNameIgnoreCaseAndIdNot(request.name(), id)) {
            throw new AppException("Tên danh mục đã tồn tại");
        }
        category.setName(request.name());
        category.setDescription(request.description());
        categoryRepository.save(category);
        auditLogService.record(ActionType.UPDATE, "Category", null, "{\"id\":\"" + id + "\"}", actorId);
        return CatalogMapper.toCategoryResponse(category);
    }

    /** UC-70: archive (soft-delete). BR-31 blocks while active items remain; BR-62 unlinks the rest. */
    @Transactional
    public void archive(UUID id, UUID actorId) {
        Category category = load(id);
        if (menuItemRepository.countByCategoryIdAndIsActiveTrueAndIsDeletedFalse(id) > 0) {
            throw new AppException("Không thể xóa danh mục còn món đang hoạt động");   // BR-31
        }
        List<MenuItem> items = menuItemRepository.findByCategoryId(id);                  // BR-62
        items.forEach(item -> item.setCategory(null));
        menuItemRepository.saveAll(items);
        category.setIsActive(false);
        categoryRepository.save(category);
        auditLogService.record(ActionType.DELETE, "Category", null, "{\"event\":\"ARCHIVE\"}", actorId);
    }

    private Category load(UUID id) {
        return categoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy danh mục"));
    }
}
