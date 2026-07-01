package com.khoga.branch;

import com.khoga.audit.AuditLogService;
import com.khoga.branch.dto.BranchSettingsResponse;
import com.khoga.branch.dto.CreateBranchRequest;
import com.khoga.branch.dto.UpdateBranchRequest;
import com.khoga.common.exception.AppException;
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
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * P1.1 unit tests for branch master-data rules: active cap (BR-54), unique name, and the
 * deactivation guards + cascade (BR-55/56).
 */
@ExtendWith(MockitoExtension.class)
class BranchServiceTest {

    @Mock private StoreRepository storeRepository;
    @Mock private UserRepository userRepository;
    @Mock private ShiftSessionRepository shiftSessionRepository;
    @Mock private OrderRepository orderRepository;
    @Mock private StaffScheduleRepository staffScheduleRepository;
    @Mock private SystemConfigService systemConfigService;
    @Mock private AuditLogService auditLogService;

    private BranchService service() {
        return new BranchService(storeRepository, userRepository, shiftSessionRepository,
                orderRepository, staffScheduleRepository, systemConfigService, auditLogService);
    }

    private CreateBranchRequest validRequest() {
        return new CreateBranchRequest("Khoga District 1", "1 Le Loi", "0900000001");
    }

    @Test
    void create_whenActiveCapReached_throws() {
        when(storeRepository.existsByNameIgnoreCase(anyString())).thenReturn(false);
        when(systemConfigService.getGlobalInt(eq("MAX_ACTIVE_BRANCHES"), anyInt())).thenReturn(3);
        when(storeRepository.countByIsActiveTrue()).thenReturn(3L);

        assertThrows(AppException.class, () -> service().create(validRequest(), UUID.randomUUID()));
        verify(storeRepository, never()).save(any());
    }

    @Test
    void create_duplicateName_throws() {
        when(storeRepository.existsByNameIgnoreCase(anyString())).thenReturn(true);

        assertThrows(AppException.class, () -> service().create(validRequest(), UUID.randomUUID()));
        verify(storeRepository, never()).save(any());
    }

    @Test
    void create_valid_savesActiveBranchAndAudits() {
        when(storeRepository.existsByNameIgnoreCase(anyString())).thenReturn(false);
        when(systemConfigService.getGlobalInt(eq("MAX_ACTIVE_BRANCHES"), anyInt())).thenReturn(10);
        when(storeRepository.countByIsActiveTrue()).thenReturn(2L);
        when(storeRepository.save(any(Store.class))).thenAnswer(inv -> {
            Store s = inv.getArgument(0);
            s.setId(UUID.randomUUID());
            return s;
        });
        UUID actor = UUID.randomUUID();

        service().create(validRequest(), actor);

        verify(storeRepository).save(any(Store.class));
        verify(auditLogService).record(any(), eq("Store"), any(), any(), eq(actor));
    }

    @Test
    void deactivate_withOpenShift_throws() {
        UUID id = UUID.randomUUID();
        Store store = activeStore(id);
        when(storeRepository.findById(id)).thenReturn(Optional.of(store));
        when(shiftSessionRepository.existsByStoreIdAndStatus(id, ShiftStatus.OPEN)).thenReturn(true);

        assertThrows(AppException.class, () -> service().deactivate(id, UUID.randomUUID()));
        verify(storeRepository, never()).save(any());
    }

    @Test
    void deactivate_withNonTerminalOrder_throws() {
        UUID id = UUID.randomUUID();
        Store store = activeStore(id);
        when(storeRepository.findById(id)).thenReturn(Optional.of(store));
        when(shiftSessionRepository.existsByStoreIdAndStatus(id, ShiftStatus.OPEN)).thenReturn(false);
        when(orderRepository.existsByStoreIdAndStatusIn(eq(id), any())).thenReturn(true);

        assertThrows(AppException.class, () -> service().deactivate(id, UUID.randomUUID()));
        verify(storeRepository, never()).save(any());
    }

    @Test
    void deactivate_valid_cascadesUsersDropsFutureSchedulesAndArchives() {
        UUID id = UUID.randomUUID();
        Store store = activeStore(id);
        User branchUser = new User();
        branchUser.setId(UUID.randomUUID());
        branchUser.setIsActive(true);
        when(storeRepository.findById(id)).thenReturn(Optional.of(store));
        when(shiftSessionRepository.existsByStoreIdAndStatus(id, ShiftStatus.OPEN)).thenReturn(false);
        when(orderRepository.existsByStoreIdAndStatusIn(eq(id), any())).thenReturn(false);
        when(userRepository.findByStoreId(id)).thenReturn(List.of(branchUser));

        service().deactivate(id, UUID.randomUUID());

        assertFalse(branchUser.getIsActive());
        assertFalse(store.getIsActive());
        verify(userRepository).saveAll(any());
        verify(staffScheduleRepository).deleteByStoreIdAndShiftDateGreaterThanEqual(eq(id), any(LocalDate.class));
        verify(storeRepository).save(store);
        // S4.2: branch deactivation carries the DEACTIVATE action with before/after active flag.
        verify(auditLogService).record(eq(ActionType.DEACTIVATE), eq("Store"),
                argThat(old -> old.contains("\"active\":true")),
                argThat(now -> now.contains("\"active\":false")), any());
    }

    @Test
    void update_recordsBeforeAndAfterSnapshot_BR80() {
        UUID id = UUID.randomUUID();
        UUID actor = UUID.randomUUID();
        Store store = activeStore(id); // name "Khoga District 1"
        when(storeRepository.findById(id)).thenReturn(Optional.of(store));
        when(storeRepository.existsByNameIgnoreCaseAndIdNot(anyString(), eq(id))).thenReturn(false);
        when(storeRepository.save(any(Store.class))).thenAnswer(inv -> inv.getArgument(0));

        service().update(id, new UpdateBranchRequest("Khoga Thu Duc", "2 Vo Van Ngan", "0908"), actor);

        verify(auditLogService).record(eq(ActionType.UPDATE), eq("Store"),
                argThat(old -> old != null && old.contains("Khoga District 1")),
                argThat(now -> now != null && now.contains("Khoga Thu Duc")), eq(actor));
    }

    @Test
    void getSettings_returnsBranchScopedConfigValues() {
        UUID id = UUID.randomUUID();
        UUID actorId = UUID.randomUUID();
        User actor = new User();
        actor.setId(actorId);
        actor.setRole(Role.SSADMIN);
        when(storeRepository.findById(id)).thenReturn(Optional.of(activeStore(id)));
        when(userRepository.findById(actorId)).thenReturn(Optional.of(actor));
        when(systemConfigService.getBranch(id, "TIMEZONE", null)).thenReturn("Asia/Ho_Chi_Minh");
        when(systemConfigService.getBranch(id, "PRINTER_ADDRESS", null)).thenReturn("192.168.1.50");

        BranchSettingsResponse res = service().getSettings(id, actorId);

        assertEquals("Asia/Ho_Chi_Minh", res.timezone());
        assertEquals("192.168.1.50", res.printerAddress());
    }

    private Store activeStore(UUID id) {
        Store store = new Store();
        store.setId(id);
        store.setName("Khoga District 1");
        store.setIsActive(true);
        return store;
    }
}
