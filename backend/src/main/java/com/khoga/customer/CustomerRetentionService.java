package com.khoga.customer;

import com.khoga.audit.AuditLogService;
import com.khoga.common.model.Customer;
import com.khoga.common.model.enums.ActionType;
import com.khoga.common.repository.CustomerRepository;
import com.khoga.config.SystemConfigService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

/**
 * BR-72 (P4, PDPA) — anonymises the personal data of customers inactive beyond a configurable window
 * ({@code CUSTOMER_PII_RETENTION_MONTHS}, default 24). Name/phone/email/birthDate are stripped while
 * the customer row (and its order history) is retained. Idempotent: once anonymised a customer no
 * longer matches the candidate query. Each anonymisation writes an audit row.
 */
@Service
public class CustomerRetentionService {

    /** Placeholder name left after PII removal. */
    public static final String ANON_NAME = "Khách ẩn danh";
    public static final String AUDIT_ENTITY = "CustomerAnonymized";

    private final CustomerRepository customerRepository;
    private final AuditLogService auditLogService;
    private final SystemConfigService config;

    public CustomerRetentionService(CustomerRepository customerRepository, AuditLogService auditLogService,
                                    SystemConfigService config) {
        this.customerRepository = customerRepository;
        this.auditLogService = auditLogService;
        this.config = config;
    }

    /** Anonymises stale customers; returns how many were processed this run. */
    @Transactional
    public int anonymizeStaleCustomers() {
        int months = config.getGlobalInt("CUSTOMER_PII_RETENTION_MONTHS", 24);
        LocalDateTime cutoff = LocalDateTime.now().minusMonths(months);

        int count = 0;
        for (Customer c : customerRepository.findAnonymizationCandidates(cutoff)) {
            c.setFullName(ANON_NAME);
            c.setPhone(null);
            c.setEmail(null);
            c.setBirthDate(null);
            customerRepository.save(c);
            auditLogService.record(ActionType.UPDATE, AUDIT_ENTITY, c.getId().toString(),
                    "{\"event\":\"PII_ANONYMIZED\"}", null);
            count++;
        }
        return count;
    }
}
