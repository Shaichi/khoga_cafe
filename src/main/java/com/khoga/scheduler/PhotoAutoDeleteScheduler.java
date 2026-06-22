package com.khoga.scheduler;

import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * BR-72 (PDPA): delete attendance photos older than 90 days, null their {@code photoUrl}, keep the
 * log. Runs at 02:00 daily. Real logic lands in P2.4 (Staff).
 */
@Slf4j
@Component
public class PhotoAutoDeleteScheduler {

    @Scheduled(cron = "0 0 2 * * *")
    public void purgeExpiredPhotos() {
        log.debug("[scheduler] PhotoAutoDelete tick — no-op until P2.4");
    }
}
