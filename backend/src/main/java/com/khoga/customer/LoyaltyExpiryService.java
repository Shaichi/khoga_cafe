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
 * BR-35 (P4) — expires loyalty points after a configurable inactivity window
 * ({@code LOYALTY_EXPIRY_MONTHS}, default 12). A customer with un-expired points and no transaction
 * since the cutoff has their balance zeroed; each expiry writes an immutable {@code "LoyaltyExpiry"}
 * audit row carrying the expired amount, which the UC-78 liability movement reads back.
 */
@Service
public class LoyaltyExpiryService {

    /** Audit entityAffected marker for an expiry event — distinct so reports can sum it. */
    public static final String AUDIT_ENTITY = "LoyaltyExpiry";

    private final CustomerRepository customerRepository;
    private final AuditLogService auditLogService;
    private final SystemConfigService config;

    public LoyaltyExpiryService(CustomerRepository customerRepository, AuditLogService auditLogService,
                                SystemConfigService config) {
        this.customerRepository = customerRepository;
        this.auditLogService = auditLogService;
        this.config = config;
    }

    /** Zeroes stale point balances; returns the total number of points expired this run. */
    @Transactional
    public int expireInactivePoints() {
        int months = config.getGlobalInt("LOYALTY_EXPIRY_MONTHS", 12);
        LocalDateTime cutoff = LocalDateTime.now().minusMonths(months);

        int totalExpired = 0;
        for (Customer c : customerRepository.findPointsExpiryCandidates(cutoff)) {
            int pts = c.getPoints() == null ? 0 : c.getPoints();
            if (pts <= 0) {
                continue;
            }
            c.setPoints(0);
            customerRepository.save(c);
            auditLogService.record(ActionType.UPDATE, AUDIT_ENTITY, c.getId().toString(),
                    "{\"event\":\"POINTS_EXPIRED\",\"points\":" + pts + "}", null);
            totalExpired += pts;
        }
        return totalExpired;
    }
}
