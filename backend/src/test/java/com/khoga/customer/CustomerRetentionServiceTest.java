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

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/** BR-72 (P4, PDPA) — inactive customers' PII is stripped while the record is kept. */
@ExtendWith(MockitoExtension.class)
class CustomerRetentionServiceTest {

    @Mock private CustomerRepository customerRepository;
    @Mock private AuditLogService auditLogService;
    @Mock private SystemConfigService config;
    @InjectMocks private CustomerRetentionService service;

    @Test
    void anonymizesPiiAndAudits() {
        when(config.getGlobalInt(eq("CUSTOMER_PII_RETENTION_MONTHS"), anyInt())).thenReturn(24);
        Customer c = new Customer();
        c.setId(UUID.randomUUID());
        c.setFullName("Nguyễn Văn A");
        c.setPhone("0900000000");
        c.setEmail("a@example.com");
        c.setBirthDate(LocalDate.of(1990, 1, 1));
        c.setPoints(50);
        when(customerRepository.findAnonymizationCandidates(any())).thenReturn(List.of(c));

        int count = service.anonymizeStaleCustomers();

        assertEquals(1, count);
        assertEquals(CustomerRetentionService.ANON_NAME, c.getFullName());
        assertNull(c.getPhone());
        assertNull(c.getEmail());
        assertNull(c.getBirthDate());
        assertEquals(50, c.getPoints()); // points/history preserved
        verify(customerRepository).save(c);
        verify(auditLogService).record(eq(ActionType.UPDATE), eq(CustomerRetentionService.AUDIT_ENTITY),
                any(), any(), isNull());
    }
}
