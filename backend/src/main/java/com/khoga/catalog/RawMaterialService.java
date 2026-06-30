package com.khoga.catalog;

import com.khoga.audit.AuditLogService;
import com.khoga.catalog.dto.CreateRawMaterialRequest;
import com.khoga.catalog.dto.RawMaterialResponse;
import com.khoga.catalog.dto.UpdateRawMaterialRequest;
import com.khoga.common.exception.AppException;
import com.khoga.common.exception.ResourceNotFoundException;
import com.khoga.common.model.RawMaterial;
import com.khoga.common.model.enums.ActionType;
import com.khoga.common.repository.RawMaterialRepository;
import com.khoga.common.repository.RecipeItemRepository;
import com.khoga.common.repository.StockItemRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.UUID;

/**
 * Raw-material master (UC-74). Code is immutable (BR-63 — never read from the update DTO); the unit
 * is locked once the material has stock or recipe usage (BR-64); removal is a soft-delete.
 */
@Service
public class RawMaterialService {

    private final RawMaterialRepository rawMaterialRepository;
    private final StockItemRepository stockItemRepository;
    private final RecipeItemRepository recipeItemRepository;
    private final AuditLogService auditLogService;

    public RawMaterialService(RawMaterialRepository rawMaterialRepository, StockItemRepository stockItemRepository,
                              RecipeItemRepository recipeItemRepository, AuditLogService auditLogService) {
        this.rawMaterialRepository = rawMaterialRepository;
        this.stockItemRepository = stockItemRepository;
        this.recipeItemRepository = recipeItemRepository;
        this.auditLogService = auditLogService;
    }

    @Transactional(readOnly = true)
    public Page<RawMaterialResponse> list(Boolean active, String search, Pageable pageable) {
        Page<RawMaterial> page;
        if (StringUtils.hasText(search)) {
            page = rawMaterialRepository.findByCodeContainingIgnoreCaseOrNameContainingIgnoreCase(
                    search, search, pageable);
        } else if (active != null) {
            page = rawMaterialRepository.findByIsActive(active, pageable);
        } else {
            page = rawMaterialRepository.findAll(pageable);
        }
        return page.map(CatalogMapper::toRawMaterialResponse);
    }

    @Transactional(readOnly = true)
    public RawMaterialResponse get(UUID id) {
        return CatalogMapper.toRawMaterialResponse(load(id));
    }

    @Transactional
    public RawMaterialResponse create(CreateRawMaterialRequest request, UUID actorId) {
        if (rawMaterialRepository.existsByCodeIgnoreCase(request.code())) {
            throw AppException.of("err.025");
        }
        RawMaterial material = new RawMaterial();
        material.setCode(request.code());
        material.setName(request.name());
        material.setUnit(request.unit());
        material.setSuggestedMinThreshold(request.suggestedMinThreshold());
        material.setStandardCost(request.standardCost());
        material.setCategory(request.category());
        material.setIsActive(true);
        RawMaterial saved = rawMaterialRepository.save(material);
        auditLogService.record(ActionType.CREATE, "RawMaterial", null,
                "{\"code\":\"" + request.code() + "\"}", actorId);
        return CatalogMapper.toRawMaterialResponse(saved);
    }

    @Transactional
    public RawMaterialResponse update(UUID id, UpdateRawMaterialRequest request, UUID actorId) {
        RawMaterial material = load(id);
        boolean unitChanged = material.getUnit() == null || !material.getUnit().equalsIgnoreCase(request.unit());
        if (unitChanged && isUnitLocked(id)) {
            throw AppException.of("err.026"); // BR-64
        }
        material.setName(request.name());
        material.setUnit(request.unit());
        material.setSuggestedMinThreshold(request.suggestedMinThreshold());
        material.setStandardCost(request.standardCost());
        material.setCategory(request.category());
        if (request.active() != null) {
            material.setIsActive(request.active());
        }
        rawMaterialRepository.save(material);
        auditLogService.record(ActionType.UPDATE, "RawMaterial", null, "{\"id\":\"" + id + "\"}", actorId);
        return CatalogMapper.toRawMaterialResponse(material);
    }

    @Transactional
    public void deactivate(UUID id, UUID actorId) {
        RawMaterial material = load(id);
        material.setIsActive(false);
        rawMaterialRepository.save(material);
        auditLogService.record(ActionType.DELETE, "RawMaterial", null, "{\"id\":\"" + id + "\"}", actorId);
    }

    private boolean isUnitLocked(UUID id) {
        return stockItemRepository.existsByRawMaterialId(id) || recipeItemRepository.existsByRawMaterialId(id);
    }

    private RawMaterial load(UUID id) {
        return rawMaterialRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy nguyên liệu"));
    }
}
