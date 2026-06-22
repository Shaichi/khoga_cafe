package com.khoga.scheduler;

import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * BR-88: auto-close shift sessions left OPEN past end of day. Runs at 23:59 daily.
 * Real logic lands in P2.2 (POS).
 */
@Slf4j
@Component
public class ShiftAutoCloseScheduler {

    @Scheduled(cron = "0 59 23 * * *")
    public void autoCloseOpenShifts() {
        log.debug("[scheduler] ShiftAutoClose tick — no-op until P2.2");
    }
}
