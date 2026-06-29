package com.khoga.report;

import com.khoga.common.model.AuditLog;
import com.khoga.common.model.User;
import com.khoga.common.model.enums.ActionType;
import com.khoga.common.repository.AuditLogRepository;
import com.khoga.report.dto.AuditChangeRow;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.when;

/** UC-77/83: read-only audit-trail projections filtered by entity type, period, actor. */
@ExtendWith(MockitoExtension.class)
class ChangeHistoryServiceTest {

    @Mock private AuditLogRepository auditLogRepository;
    @InjectMocks private ChangeHistoryService service;

    private final LocalDate from = LocalDate.of(2026, 5, 1);
    private final LocalDate to = LocalDate.of(2026, 5, 31);
    private final Pageable page = PageRequest.of(0, 20);

    private AuditLog log(String entity, ActionType action) {
        User actor = new User();
        actor.setId(UUID.randomUUID());
        actor.setUsername("biz_an");
        AuditLog a = new AuditLog();
        a.setId(UUID.randomUUID());
        a.setUser(actor);
        a.setActionType(action);
        a.setEntityAffected(entity);
        a.setOldValueJson("28000");
        a.setNewValueJson("30000");
        return a;
    }

    @Test
    void priceVoucherHistory_typeAll_queriesBothEntities() {
        when(auditLogRepository.findChangeHistory(any(), isNull(), any(), any(), eq(page)))
                .thenReturn(new PageImpl<>(List.of(log("MenuItem", ActionType.UPDATE))));

        Page<AuditChangeRow> result = service.priceVoucherHistory(from, to, "ALL", null, page);

        @SuppressWarnings("unchecked")
        ArgumentCaptor<List<String>> entities = ArgumentCaptor.forClass(List.class);
        org.mockito.Mockito.verify(auditLogRepository)
                .findChangeHistory(entities.capture(), isNull(), any(), any(), eq(page));
        assertTrue(entities.getValue().containsAll(List.of("MenuItem", "Voucher")));
        assertEquals("biz_an", result.getContent().get(0).actor());
        assertEquals("MenuItem", result.getContent().get(0).entity());
    }

    @Test
    void priceVoucherHistory_typeVoucher_queriesVoucherOnly() {
        when(auditLogRepository.findChangeHistory(eq(List.of("Voucher")), isNull(), any(), any(), eq(page)))
                .thenReturn(new PageImpl<>(List.of(log("Voucher", ActionType.CREATE))));

        Page<AuditChangeRow> result = service.priceVoucherHistory(from, to, "VOUCHER", null, page);

        assertEquals("Voucher", result.getContent().get(0).entity());
    }

    @Test
    void accessReview_queriesUserEntity() {
        UUID actorFilter = UUID.randomUUID();
        when(auditLogRepository.findChangeHistory(eq(List.of("User")), eq(actorFilter), any(), any(), eq(page)))
                .thenReturn(new PageImpl<>(List.of(log("User", ActionType.UPDATE))));

        Page<AuditChangeRow> result = service.accessReview(from, to, actorFilter, page);

        assertEquals("User", result.getContent().get(0).entity());
    }
}
