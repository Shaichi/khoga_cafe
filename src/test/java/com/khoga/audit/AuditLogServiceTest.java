package com.khoga.audit;

import com.khoga.common.model.AuditLog;
import com.khoga.common.model.User;
import com.khoga.common.model.enums.ActionType;
import com.khoga.common.repository.AuditLogRepository;
import com.khoga.common.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * P0.3 unit tests for the append-only audit recorder. No Spring context — pure logic over mocked repos.
 */
@ExtendWith(MockitoExtension.class)
class AuditLogServiceTest {

    @Mock
    private AuditLogRepository auditLogRepository;
    @Mock
    private UserRepository userRepository;
    @InjectMocks
    private AuditLogService auditLogService;

    @Test
    void record_persistsSingleRowWithActorAndJson() {
        UUID actorId = UUID.randomUUID();
        User actor = new User();
        actor.setId(actorId);
        when(userRepository.findById(actorId)).thenReturn(Optional.of(actor));
        when(auditLogRepository.save(any(AuditLog.class))).thenAnswer(inv -> inv.getArgument(0));

        auditLogService.record(ActionType.UPDATE, "MenuItem", "{\"price\":10}", "{\"price\":12}", actorId);

        ArgumentCaptor<AuditLog> captor = ArgumentCaptor.forClass(AuditLog.class);
        verify(auditLogRepository).save(captor.capture());
        AuditLog row = captor.getValue();
        assertEquals(ActionType.UPDATE, row.getActionType());
        assertEquals("MenuItem", row.getEntityAffected());
        assertEquals("{\"price\":10}", row.getOldValueJson());
        assertEquals("{\"price\":12}", row.getNewValueJson());
        assertSame(actor, row.getUser());
    }

    @Test
    void record_allowsNullActor_forSystemActions() {
        when(auditLogRepository.save(any(AuditLog.class))).thenAnswer(inv -> inv.getArgument(0));

        AuditLog saved = auditLogService.record(ActionType.CREATE, "StockTransaction", null, "{}", null);

        verify(userRepository, never()).findById(any());
        assertNull(saved.getUser());
    }
}
