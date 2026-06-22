package com.khoga.scheduler;

import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * BR-88: READY orders idle &gt; 15 minutes become ABANDONED (no stock refund). Runs every minute.
 * Real logic lands in P2.3 (Order).
 */
@Slf4j
@Component
public class OrderTimeoutScheduler {

    @Scheduled(cron = "0 * * * * *")
    public void abandonStaleReadyOrders() {
        log.debug("[scheduler] OrderTimeout tick — no-op until P2.3");
    }
}
