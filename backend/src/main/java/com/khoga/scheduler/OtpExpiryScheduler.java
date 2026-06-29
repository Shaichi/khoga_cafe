package com.khoga.scheduler;

import com.khoga.auth.OtpStore;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Sweeps expired one-time passwords from the in-memory {@link OtpStore} every 5 minutes (BR-16).
 * Verification already rejects expired codes on read; this just bounds memory between accesses.
 */
@Slf4j
@Component
public class OtpExpiryScheduler {

    private final OtpStore otpStore;

    public OtpExpiryScheduler(OtpStore otpStore) {
        this.otpStore = otpStore;
    }

    @Scheduled(fixedRate = 300_000L)
    public void purgeExpiredOtps() {
        int removed = otpStore.purgeExpired();
        if (removed > 0) {
            log.debug("[scheduler] OtpExpiry — purged {} expired OTP(s)", removed);
        }
    }
}
