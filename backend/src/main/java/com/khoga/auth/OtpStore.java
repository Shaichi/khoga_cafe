package com.khoga.auth;

import org.springframework.stereotype.Component;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * In-memory one-time-password store for the P1B auth flows — password reset (UC-03/04/05) and HQ
 * login MFA (BR-83). Each entry has a 6-digit code, a 10-minute expiry (BR-16) and an attempt
 * counter that locks the challenge after 3 wrong tries (BR-17).
 *
 * <p><b>Limitation (by design for P1B):</b> a {@link ConcurrentHashMap} does not survive a restart
 * and is not shared across nodes. Per the build plan this is acceptable for the first cut; a durable
 * store (DB/Redis) lands in P4. The {@code OtpExpiryScheduler} sweeps stale entries (BR-16).
 */
@Component
public class OtpStore {

    /** Outcome of a {@link #verify} call. */
    public enum Result { OK, INVALID, EXPIRED, LOCKED, NOT_FOUND }

    static final int TTL_MINUTES = 10;
    static final int MAX_ATTEMPTS = 3;

    private final SecureRandom random = new SecureRandom();
    private final Map<String, Entry> store = new ConcurrentHashMap<>();

    /** Issues a fresh OTP for {@code key} (replacing any previous one) and returns the plain code. */
    public String issue(String key, UUID userId) {
        return issue(key, userId, LocalDateTime.now().plusMinutes(TTL_MINUTES));
    }

    /** Test seam: issue with an explicit expiry. */
    String issue(String key, UUID userId, LocalDateTime expiresAt) {
        String code = String.format("%06d", random.nextInt(1_000_000));
        store.put(key, new Entry(userId, code, expiresAt, 0));
        return code;
    }

    /**
     * Validates {@code code} for {@code key}. A wrong code increments the attempt counter and locks
     * the challenge once {@link #MAX_ATTEMPTS} is reached (BR-17). A correct code returns {@code OK}
     * but leaves the entry in place — the caller must {@link #consume} it.
     */
    public Result verify(String key, String code) {
        Entry e = store.get(key);
        if (e == null) {
            return Result.NOT_FOUND;
        }
        if (e.expiresAt.isBefore(LocalDateTime.now())) {
            store.remove(key);
            return Result.EXPIRED;
        }
        if (e.attempts >= MAX_ATTEMPTS) {
            return Result.LOCKED;
        }
        if (!e.code.equals(code)) {
            int attempts = e.attempts + 1;
            store.put(key, new Entry(e.userId, e.code, e.expiresAt, attempts));
            return attempts >= MAX_ATTEMPTS ? Result.LOCKED : Result.INVALID;
        }
        return Result.OK;
    }

    /** Removes the entry for {@code key} and returns its user id (or {@code null} if absent). */
    public UUID consume(String key) {
        Entry e = store.remove(key);
        return e == null ? null : e.userId;
    }

    /** BR-16 housekeeping — drop expired entries; returns how many were removed. */
    public int purgeExpired() {
        LocalDateTime now = LocalDateTime.now();
        int[] removed = {0};
        store.entrySet().removeIf(en -> {
            boolean expired = en.getValue().expiresAt.isBefore(now);
            if (expired) {
                removed[0]++;
            }
            return expired;
        });
        return removed[0];
    }

    private record Entry(UUID userId, String code, LocalDateTime expiresAt, int attempts) {
    }
}
