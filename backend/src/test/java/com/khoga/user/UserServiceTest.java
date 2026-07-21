package com.khoga.user;

import com.khoga.audit.AuditLogService;
import com.khoga.common.exception.AppException;
import com.khoga.common.model.User;
import com.khoga.common.model.enums.ActionType;
import com.khoga.common.model.enums.Role;
import com.khoga.common.repository.AuditLogRepository;
import com.khoga.common.repository.StoreRepository;
import com.khoga.common.repository.UserRepository;
import com.khoga.integration.EmailService;
import com.khoga.user.dto.CreateUserRequest;
import com.khoga.user.dto.UpdateUserRequest;
import com.khoga.user.dto.UserResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/** P1.2 unit tests: account creation (BR-22/57/58/81) and the BR-82/BR-23 guards. */
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock private UserRepository userRepository;
    @Mock private StoreRepository storeRepository;
    @Mock private AuditLogRepository auditLogRepository;
    @Mock private AuditLogService auditLogService;
    @Mock private EmailService emailService;

    private UserService service;

    @BeforeEach
    void setUp() {
        service = new UserService(userRepository, storeRepository, auditLogRepository, auditLogService,
                emailService, new UsernameGenerator(), new BCryptPasswordEncoder());
    }

    @Test
    void create_allocatesEmpIdUsernameTempPasswordEmailsAndAudits() {
        when(userRepository.count()).thenReturn(42L);
        when(userRepository.existsByUsername(anyString())).thenReturn(false);
        when(userRepository.save(any(User.class))).thenAnswer(inv -> inv.getArgument(0));
        UUID actor = UUID.randomUUID();

        UserResponse response = service.create(
                new CreateUserRequest("Nguyễn Văn An", Role.CASHIER, "an@khoga.com", "0900000009", null), actor);

        assertEquals("EMP-043", response.employeeId());
        assertEquals("anNV43", response.username());

        ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(captor.capture());
        User saved = captor.getValue();
        assertTrue(Boolean.TRUE.equals(saved.getMustChangePassword()));
        assertTrue(saved.getPasswordHash() != null && !saved.getPasswordHash().isBlank());

        verify(emailService).send(eq("an@khoga.com"), anyString(), anyString());
        verify(auditLogService).record(eq(ActionType.CREATE), eq("User"), any(), any(), eq(actor));
    }

    @Test
    void create_skipsRetiredEmployeeNumber() {
        when(userRepository.count()).thenReturn(2L);                          // candidate starts at EMP-003
        when(userRepository.existsByEmployeeId("EMP-003")).thenReturn(true);  // retired/taken → skip
        when(userRepository.existsByEmployeeId("EMP-004")).thenReturn(false);
        when(userRepository.existsByUsername(anyString())).thenReturn(false);
        when(userRepository.save(any(User.class))).thenAnswer(inv -> inv.getArgument(0));

        UserResponse response = service.create(
                new CreateUserRequest("Phạm Dũng", Role.CASHIER, "dung@khoga.com", "0900000003", null),
                UUID.randomUUID());

        assertEquals("EMP-004", response.employeeId());   // no reuse of the retired EMP-003
    }

    @Test
    void create_duplicateEmail_throws() {
        when(userRepository.existsByEmail("dup@khoga.com")).thenReturn(true);

        assertThrows(AppException.class, () -> service.create(
                new CreateUserRequest("Trần Bình", Role.CASHIER, "dup@khoga.com", "0900000001", null),
                UUID.randomUUID()));

        verify(userRepository, org.mockito.Mockito.never()).save(any(User.class));
    }

    @Test
    void create_duplicatePhone_throws() {
        when(userRepository.existsByPhone("0900000002")).thenReturn(true);

        assertThrows(AppException.class, () -> service.create(
                new CreateUserRequest("Lê Cường", Role.CASHIER, "cuong@khoga.com", "0900000002", null),
                UUID.randomUUID()));

        verify(userRepository, org.mockito.Mockito.never()).save(any(User.class));
    }

    @Test
    void update_selfRoleChange_throws() {
        UUID actor = UUID.randomUUID();
        User self = userOf(actor, Role.CASHIER);
        when(userRepository.findById(actor)).thenReturn(Optional.of(self));

        assertThrows(AppException.class, () ->
                service.update(actor, new UpdateUserRequest("Self", Role.SSADMIN, null, null, null), actor));
    }

    @Test
    void deactivate_lastActiveAdmin_throws() {
        UUID id = UUID.randomUUID();
        User admin = userOf(id, Role.SSADMIN);
        admin.setIsActive(true);
        when(userRepository.findById(id)).thenReturn(Optional.of(admin));
        when(userRepository.countByRoleAndIsActiveTrue(Role.SSADMIN)).thenReturn(1L);

        assertThrows(AppException.class, () -> service.setActive(id, false, UUID.randomUUID()));
    }

    @Test
    void deactivate_self_throws() {
        UUID actor = UUID.randomUUID();
        User self = userOf(actor, Role.STORE_MANAGER);
        self.setIsActive(true);
        when(userRepository.findById(actor)).thenReturn(Optional.of(self));

        assertThrows(AppException.class, () -> service.setActive(actor, false, actor));
    }

    @Test
    void update_recordsBeforeAndAfterSnapshot_BR81() {
        UUID id = UUID.randomUUID();
        UUID actor = UUID.randomUUID();
        User user = userOf(id, Role.CASHIER);
        user.setEmail("old@khoga.com");
        user.setPhone("0900000000");
        when(userRepository.findById(id)).thenReturn(Optional.of(user));
        when(userRepository.existsByEmailAndIdNot("new@khoga.com", id)).thenReturn(false);
        when(userRepository.existsByPhoneAndIdNot("0900000001", id)).thenReturn(false);
        when(userRepository.save(any(User.class))).thenAnswer(inv -> inv.getArgument(0));

        service.update(id, new UpdateUserRequest("Updated Name", null, null, "new@khoga.com", "0900000001"), actor);

        verify(auditLogService).record(eq(ActionType.UPDATE), eq("User"),
                argThat(old -> old != null && old.contains("old@khoga.com")),
                argThat(now -> now != null && now.contains("new@khoga.com")), eq(actor));
    }

    @Test
    void setActive_deactivate_usesDeactivateActionWithBeforeAfter_S42() {
        UUID id = UUID.randomUUID();
        UUID actor = UUID.randomUUID();
        User user = userOf(id, Role.CASHIER);
        when(userRepository.findById(id)).thenReturn(Optional.of(user));
        when(userRepository.save(any(User.class))).thenAnswer(inv -> inv.getArgument(0));

        service.setActive(id, false, actor);

        verify(auditLogService).record(eq(ActionType.DEACTIVATE), eq("User"),
                argThat(old -> old.contains("\"active\":true")),
                argThat(now -> now.contains("\"active\":false")), eq(actor));
    }

    private static User userOf(UUID id, Role role) {
        User u = new User();
        u.setId(id);
        u.setRole(role);
        u.setIsActive(true);
        return u;
    }
}
