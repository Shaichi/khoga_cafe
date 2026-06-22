package com.khoga.scheduler;

import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * BR-04 / MSG07: nightly low-stock sweep across branches, emailing store managers. Runs at 22:00.
 * Real logic lands in P2.1 (Inventory).
 */
@Slf4j
@Component
public class LowStockAlertScheduler {

    @Scheduled(cron = "0 0 22 * * *")
    public void alertLowStock() {
        log.debug("[scheduler] LowStockAlert tick — no-op until P2.1");
    }
}
