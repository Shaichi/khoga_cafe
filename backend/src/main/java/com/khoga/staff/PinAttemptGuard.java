package com.khoga.staff;

import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * BR-93 brute-force guard for the attendance PIN pad. A pure PIN-only check-in cannot attribute a
 * wrong (no-match) PIN to a specific employee, so the lockout is scoped to the <b>branch terminal</b>:
 * after {@code maxAttempts} consecutive failed PIN entries at a store the terminal is locked for a
 * cooldown window; any successful identify clears the streak. The per-user {@code pinLockedUntil}
 * lock (set by admin / other flows) is enforced separately in {@code AttendanceService}.
 *
 * <p>State is in-memory (per node) — appropriate for a physical-terminal rate limit; a restart simply
 * grants a fresh window. Move to a shared store only if attendance runs multi-node.
 */
@Component
public class PinAttemptGuard {

    private static final class Streak {
        int failures;
        LocalDateTime lockedUntil;
    }

    private final Map<UUID, Streak> byStore = new ConcurrentHashMap<>();

    /** True while the store terminal is inside an active lockout window. */
    public boolean isLocked(UUID storeId) {
        Streak s = byStore.get(storeId);
        return s != null && s.lockedUntil != null && s.lockedUntil.isAfter(LocalDateTime.now());
    }

    /** Charge one failed PIN entry to the terminal; lock it once {@code maxAttempts} is reached. */
    public synchronized void recordFailure(UUID storeId, int maxAttempts, int lockMinutes) {
        Streak s = byStore.computeIfAbsent(storeId, k -> new Streak());
        s.failures++;
        if (s.failures >= maxAttempts) {
            s.lockedUntil = LocalDateTime.now().plusMinutes(lockMinutes);
        }
    }

    /** Successful identify — wipe the terminal's failure streak and any lock. */
    public void reset(UUID storeId) {
        byStore.remove(storeId);
    }
}
