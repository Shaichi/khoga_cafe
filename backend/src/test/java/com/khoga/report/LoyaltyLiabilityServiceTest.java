package com.khoga.report;

import com.khoga.common.model.AuditLog;
import com.khoga.common.repository.AuditLogRepository;
import com.khoga.common.repository.CustomerRepository;
import com.khoga.common.repository.OrderRepository;
import com.khoga.customer.LoyaltyExpiryService;
import com.khoga.report.dto.LoyaltyLiabilityReport;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.when;

/** UC-78: outstanding points + movement reconciliation (opening + issued − redeemed − expired = closing). */
@ExtendWith(MockitoExtension.class)
class LoyaltyLiabilityServiceTest {

    @Mock private CustomerRepository customerRepository;
    @Mock private OrderRepository orderRepository;
    @Mock private AuditLogRepository auditLogRepository;
    @Mock private ReportScopeResolver scope;
    @InjectMocks private LoyaltyLiabilityService service;

    private final UUID actor = UUID.randomUUID();

    private AuditLog expiry(int points) {
        AuditLog a = new AuditLog();
        a.setEntityAffected(LoyaltyExpiryService.AUDIT_ENTITY);
        a.setNewValueJson("{\"event\":\"POINTS_EXPIRED\",\"points\":" + points + "}");
        return a;
    }

    @Test
    void liability_reconcilesMovementWithRealExpiry() {
        when(scope.resolveBranch(actor, null)).thenReturn(null);
        when(customerRepository.sumOutstandingPoints()).thenReturn(1_284_500L);
        when(orderRepository.sumPointsEarned(isNull(), any(), any())).thenReturn(210_500L);
        when(orderRepository.sumPointsRedeemed(isNull(), any(), any())).thenReturn(98_000L);
        when(auditLogRepository.findByEntityAffectedAndCreatedAtBetween(
                eq(LoyaltyExpiryService.AUDIT_ENTITY), any(), any()))
                .thenReturn(List.of(expiry(10_000), expiry(8_000)));

        LoyaltyLiabilityReport r = service.liability(LocalDate.of(2026, 5, 1), LocalDate.of(2026, 5, 31), null, actor);

        assertEquals(1_284_500L, r.outstandingPoints());
        assertEquals(18_000L, r.movement().expired());
        // opening = closing − issued + redeemed + expired = 1,284,500 − 210,500 + 98,000 + 18,000 = 1,190,000
        assertEquals(1_190_000L, r.movement().opening());
        // identity holds: opening + issued − redeemed − expired = closing
        long m = r.movement().opening() + r.movement().issued() - r.movement().redeemed() - r.movement().expired();
        assertEquals(r.movement().closing(), m);
    }
}
