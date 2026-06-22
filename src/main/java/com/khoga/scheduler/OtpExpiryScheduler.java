package com.khoga.scheduler;

import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Cleans up expired one-time passwords (BR-16). Runs every 5 minutes. Real logic lands in P1B (Auth
 * hardening) once OTP storage exists.
 */
@Slf4j
@Component
public class OtpExpiryScheduler {

    @Scheduled(fixedRate = 300_000L)
    public void purgeExpiredOtps() {
        log.debug("[scheduler] OtpExpiry tick — no-op until P1B");
    }
}
