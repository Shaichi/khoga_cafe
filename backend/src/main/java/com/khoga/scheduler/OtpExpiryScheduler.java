package com.khoga.scheduler;

import com.khoga.common.repository.OtpRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

/**
 * Sweeps expired one-time passwords from the database every 5 minutes (BR-16).
 * Verification already rejects expired codes on read; this just bounds database size.
 */
@Slf4j
@Component
public class OtpExpiryScheduler {

    private final OtpRepository otpRepository;

    public OtpExpiryScheduler(OtpRepository otpRepository) {
        this.otpRepository = otpRepository;
    }

    @Scheduled(fixedRate = 300_000L)
    @Transactional
    public void purgeExpiredOtps() {
        int removed = otpRepository.deleteExpired(LocalDateTime.now());
        if (removed > 0) {
            log.debug("[scheduler] OtpExpiry — purged {} expired OTP(s) from DB", removed);
        }
    }
}
