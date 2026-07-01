package com.khoga.auth;

import com.khoga.common.model.OtpEntity;
import com.khoga.common.repository.OtpRepository;
import org.springframework.stereotype.Component;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * DB-backed one-time-password store for the P1B auth flows — password reset (UC-03/04/05) and HQ
 * login MFA (BR-83). Each entry has a 6-digit code, a 10-minute expiry (BR-16) and an attempt
 * counter that locks the challenge after 3 wrong tries (BR-17).
 */
@Component
public class OtpStore {

    public enum Result { OK, INVALID, EXPIRED, LOCKED, NOT_FOUND }

    static final int TTL_MINUTES = 10;
    static final int MAX_ATTEMPTS = 3;

    private final SecureRandom random = new SecureRandom();
    private final OtpRepository otpRepository;

    public OtpStore(OtpRepository otpRepository) {
        this.otpRepository = otpRepository;
    }

    public String issue(String key, UUID userId) {
        return issue(key, userId, LocalDateTime.now().plusMinutes(TTL_MINUTES));
    }

    String issue(String key, UUID userId, LocalDateTime expiresAt) {
        String code = String.format("%06d", random.nextInt(1_000_000));
        OtpEntity e = new OtpEntity();
        e.setId(key);
        e.setUserId(userId);
        e.setCode(code);
        e.setExpiresAt(expiresAt);
        e.setAttempts(0);
        otpRepository.save(e);
        return code;
    }

    public Result verify(String key, String code) {
        OtpEntity e = otpRepository.findById(key).orElse(null);
        if (e == null) {
            return Result.NOT_FOUND;
        }
        if (e.getExpiresAt().isBefore(LocalDateTime.now())) {
            otpRepository.deleteById(key);
            return Result.EXPIRED;
        }
        if (e.getAttempts() >= MAX_ATTEMPTS) {
            return Result.LOCKED;
        }
        if (!e.getCode().equals(code)) {
            int attempts = e.getAttempts() + 1;
            e.setAttempts(attempts);
            otpRepository.save(e);
            return attempts >= MAX_ATTEMPTS ? Result.LOCKED : Result.INVALID;
        }
        return Result.OK;
    }

    public UUID consume(String key) {
        OtpEntity e = otpRepository.findById(key).orElse(null);
        if (e == null) {
            return null;
        }
        otpRepository.deleteById(key);
        return e.getUserId();
    }

    /** Owner of a challenge without consuming it — lets the MFA flow charge a failure to the account (BR-17). */
    public UUID userIdFor(String key) {
        return otpRepository.findById(key).map(OtpEntity::getUserId).orElse(null);
    }
}
