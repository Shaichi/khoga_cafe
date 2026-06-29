package com.khoga.customer;

import com.khoga.audit.AuditLogService;
import com.khoga.common.model.Customer;
import com.khoga.common.model.enums.ActionType;
import com.khoga.common.repository.CustomerRepository;
import com.khoga.config.SystemConfigService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/** BR-35 (P4) — stale point balances are zeroed and the expired amount is audited. */
@ExtendWith(MockitoExtension.class)
class LoyaltyExpiryServiceTest {

    @Mock private CustomerRepository customerRepository;
    @Mock private AuditLogService auditLogService;
    @Mock private SystemConfigService config;
    @InjectMocks private LoyaltyExpiryService service;

    private Customer customer(int points) {
        Customer c = new Customer();
        c.setId(UUID.randomUUID());
        c.setPoints(points);
        return c;
    }

    @Test
    void expiresStalePointsAndAuditsTheAmount() {
        when(config.getGlobalInt(eq("LOYALTY_EXPIRY_MONTHS"), anyInt())).thenReturn(12);
        Customer a = customer(1500);
        Customer b = customer(300);
        when(customerRepository.findPointsExpiryCandidates(any())).thenReturn(List.of(a, b));

        int total = service.expireInactivePoints();

        assertEquals(1800, total);
        assertEquals(0, a.getPoints());
        assertEquals(0, b.getPoints());
        verify(customerRepository).save(a);
        verify(auditLogService).record(eq(ActionType.UPDATE), eq(LoyaltyExpiryService.AUDIT_ENTITY),
                any(), contains("1500"), isNull());
    }
}
