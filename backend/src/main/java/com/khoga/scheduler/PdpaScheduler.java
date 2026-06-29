package com.khoga.scheduler;

import com.khoga.customer.CustomerRetentionService;
import com.khoga.customer.LoyaltyExpiryService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * P4 data-retention timers. Loyalty points expire after inactivity (BR-35); customer PII is
 * anonymised after a longer inactivity window (BR-72). Both run nightly off-peak. The actual rules
 * live in the customer services; this is just the schedule.
 */
@Slf4j
@Component
public class PdpaScheduler {

    private final LoyaltyExpiryService loyaltyExpiryService;
    private final CustomerRetentionService customerRetentionService;

    public PdpaScheduler(LoyaltyExpiryService loyaltyExpiryService,
                         CustomerRetentionService customerRetentionService) {
        this.loyaltyExpiryService = loyaltyExpiryService;
        this.customerRetentionService = customerRetentionService;
    }

    /** BR-35 — expire stale loyalty points at 02:30 daily. */
    @Scheduled(cron = "0 30 2 * * *")
    public void expireLoyaltyPoints() {
        int expired = loyaltyExpiryService.expireInactivePoints();
        if (expired > 0) {
            log.info("[scheduler] LoyaltyExpiry — expired {} point(s)", expired);
        }
    }

    /** BR-72 (PDPA) — anonymise inactive customers' personal data at 03:00 daily. */
    @Scheduled(cron = "0 0 3 * * *")
    public void anonymizeStaleCustomers() {
        int count = customerRetentionService.anonymizeStaleCustomers();
        if (count > 0) {
            log.info("[scheduler] PDPA — anonymised {} customer(s)", count);
        }
    }
}
