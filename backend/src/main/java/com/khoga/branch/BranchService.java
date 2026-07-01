package com.khoga.branch;

import com.khoga.audit.AuditJson;
import com.khoga.audit.AuditLogService;
import com.khoga.branch.dto.BranchResponse;
import com.khoga.branch.dto.BranchSettingsRequest;
import com.khoga.branch.dto.BranchSettingsResponse;
import com.khoga.branch.dto.CreateBranchRequest;
import com.khoga.branch.dto.UpdateBranchRequest;
import com.khoga.common.exception.AppException;
import com.khoga.common.exception.ResourceNotFoundException;
import com.khoga.common.model.Store;
import com.khoga.common.model.User;
import com.khoga.common.model.enums.ActionType;
import com.khoga.common.model.enums.OrderStatus;
import com.khoga.common.model.enums.Role;
import com.khoga.common.model.enums.ShiftStatus;
import com.khoga.common.repository.OrderRepository;
import com.khoga.common.repository.ShiftSessionRepository;
import com.khoga.common.repository.StaffScheduleRepository;
import com.khoga.common.repository.StoreRepository;
import com.khoga.common.repository.UserRepository;
import com.khoga.config.SystemConfigService;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * Branch (Store) master data (UC-63/64/65/42). HQ (SSADMIN) manages the chain; a store manager may
 * only tune their own branch's settings (enforced in {@link #updateSettings}). Active-branch count
 * is capped by {@code MAX_ACTIVE_BRANCHES} (BR-54); deactivation is guarded and cascades (BR-55/56).
 */
@Service
public class BranchService {

    static final int DEFAULT_MAX_ACTIVE_BRANCHES = 10;
    private static final Set<OrderStatus> NON_TERMINAL_ORDER_STATUSES =
            EnumSet.of(OrderStatus.PENDING, OrderStatus.PREPARING, OrderStatus.HOLD, OrderStatus.READY);

    private final StoreRepository storeRepository;
    private final UserRepository userRepository;
    private final ShiftSessionRepository shiftSessionRepository;
    private final OrderRepository orderRepository;
    private final StaffScheduleRepository staffScheduleRepository;
    private final SystemConfigService systemConfigService;
    private final AuditLogService auditLogService;

    public BranchService(StoreRepository storeRepository, UserRepository userRepository,
                         ShiftSessionRepository shiftSessionRepository, OrderRepository orderRepository,
                         StaffScheduleRepository staffScheduleRepository, SystemConfigService systemConfigService,
                         AuditLogService auditLogService) {
        this.storeRepository = storeRepository;
        this.userRepository = userRepository;
        this.shiftSessionRepository = shiftSessionRepository;
        this.orderRepository = orderRepository;
        this.staffScheduleRepository = staffScheduleRepository;
        this.systemConfigService = systemConfigService;
        this.auditLogService = auditLogService;
    }

    @Transactional(readOnly = true)
    public Page<BranchResponse> list(Boolean active, Pageable pageable) {
        Page<Store> page = (active == null)
                ? storeRepository.findAll(pageable)
                : storeRepository.findByIsActive(active, pageable);
        return page.map(BranchMapper::toResponse);
    }

    @Transactional(readOnly = true)
    public BranchResponse get(UUID id) {
        return BranchMapper.toResponse(load(id));
    }

    @Transactional
    public BranchResponse create(CreateBranchRequest request, UUID actorId) {
        if (storeRepository.existsByNameIgnoreCase(request.name())) {
            throw AppException.of("err.012");
        }
        int max = systemConfigService.getGlobalInt("MAX_ACTIVE_BRANCHES", DEFAULT_MAX_ACTIVE_BRANCHES);
        if (storeRepository.countByIsActiveTrue() >= max) {
            throw AppException.of("MSG16", max);   // BR-54 — max active branches reached
        }
        Store store = new Store();
        store.setName(request.name());
        store.setAddress(request.address());
        store.setPhone(request.phone());
        store.setIsActive(true);
        Store saved = storeRepository.save(store);
        auditLogService.record(ActionType.CREATE, "Store", null,
                "{\"name\":\"" + request.name() + "\"}", actorId);
        return BranchMapper.toResponse(saved);
    }

    @Transactional
    public BranchResponse update(UUID id, UpdateBranchRequest request, UUID actorId) {
        Store store = load(id);
        if (storeRepository.existsByNameIgnoreCaseAndIdNot(request.name(), id)) {
            throw AppException.of("err.013");
        }
        String oldJson = branchSnapshot(store);         // BR-80 before-image
        store.setName(request.name());
        store.setAddress(request.address());
        store.setPhone(request.phone());
        storeRepository.save(store);
        auditLogService.record(ActionType.UPDATE, "Store", oldJson, branchSnapshot(store), actorId);
        return BranchMapper.toResponse(store);
    }

    /** UC-65 / BR-55 + BR-56: guard against in-flight work, then cascade and archive. */
    @Transactional
    public void deactivate(UUID id, UUID actorId) {
        Store store = load(id);
        if (Boolean.FALSE.equals(store.getIsActive())) {
            throw AppException.of("err.014");
        }
        if (shiftSessionRepository.existsByStoreIdAndStatus(id, ShiftStatus.OPEN)) {
            throw AppException.of("err.015");        // BR-55
        }
        if (orderRepository.existsByStoreIdAndStatusIn(id, NON_TERMINAL_ORDER_STATUSES)) {
            throw AppException.of("err.016");      // BR-55
        }
        List<User> branchUsers = userRepository.findByStoreId(id);                            // BR-56
        branchUsers.forEach(user -> user.setIsActive(false));
        userRepository.saveAll(branchUsers);
        staffScheduleRepository.deleteByStoreIdAndShiftDateGreaterThanEqual(id, LocalDate.now());
        store.setIsActive(false);
        storeRepository.save(store);
        String oldJson = AuditJson.snapshot().put("active", true).json();
        String newJson = AuditJson.snapshot().put("active", false).json();
        auditLogService.record(ActionType.DEACTIVATE, "Store", oldJson, newJson, actorId);
    }

    /** BR-80 before/after image of the mutable branch fields. */
    private String branchSnapshot(Store store) {
        return AuditJson.snapshot()
                .put("name", store.getName())
                .put("address", store.getAddress())
                .put("phone", store.getPhone())
                .json();
    }

    /** UC-42: read current branch settings, scoped like {@link #updateSettings} (manager = own branch). */
    @Transactional(readOnly = true)
    public BranchSettingsResponse getSettings(UUID id, UUID actorId) {
        load(id);
        User actor = userRepository.findById(actorId)
                .orElseThrow(() -> AppException.of("err.017"));
        if (actor.getRole() == Role.STORE_MANAGER
                && (actor.getStore() == null || !id.equals(actor.getStore().getId()))) {
            throw new AccessDeniedException("Chỉ được xem cấu hình chi nhánh của mình");
        }
        return new BranchSettingsResponse(
                systemConfigService.getBranch(id, "TIMEZONE", null),
                systemConfigService.getBranch(id, "PRINTER_ADDRESS", null));
    }

    /** UC-42: a store manager may configure only their own branch (BR-47/48). */
    @Transactional
    public BranchResponse updateSettings(UUID id, BranchSettingsRequest request, UUID actorId) {
        Store store = load(id);
        User actor = userRepository.findById(actorId)
                .orElseThrow(() -> AppException.of("err.018"));
        if (actor.getRole() == Role.STORE_MANAGER
                && (actor.getStore() == null || !id.equals(actor.getStore().getId()))) {
            throw new AccessDeniedException("Chỉ được cấu hình chi nhánh của mình");
        }
        if (request.timezone() != null) {
            systemConfigService.setBranchConfig(store, "TIMEZONE", request.timezone(), actorId.toString());
        }
        if (request.printerAddress() != null) {
            systemConfigService.setBranchConfig(store, "PRINTER_ADDRESS", request.printerAddress(), actorId.toString());
        }
        auditLogService.record(ActionType.UPDATE, "SystemConfig", null,
                "{\"event\":\"BRANCH_SETTINGS\",\"storeId\":\"" + id + "\"}", actorId);
        return BranchMapper.toResponse(store);
    }

    private Store load(UUID id) {
        return storeRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy chi nhánh"));
    }
}
