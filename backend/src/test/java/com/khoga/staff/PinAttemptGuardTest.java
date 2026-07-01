package com.khoga.staff;

import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** BR-93 terminal lockout logic: lock after N failures, stay open below threshold, reset on success. */
class PinAttemptGuardTest {

    private final PinAttemptGuard guard = new PinAttemptGuard();
    private final UUID store = UUID.randomUUID();

    @Test
    void notLocked_initially() {
        assertFalse(guard.isLocked(store));
    }

    @Test
    void belowThreshold_staysOpen() {
        guard.recordFailure(store, 3, 15);
        guard.recordFailure(store, 3, 15);
        assertFalse(guard.isLocked(store));
    }

    @Test
    void locksAtThreshold() {
        guard.recordFailure(store, 3, 15);
        guard.recordFailure(store, 3, 15);
        guard.recordFailure(store, 3, 15);
        assertTrue(guard.isLocked(store));
    }

    @Test
    void reset_clearsLock() {
        guard.recordFailure(store, 1, 15);
        assertTrue(guard.isLocked(store));

        guard.reset(store);

        assertFalse(guard.isLocked(store));
    }

    @Test
    void zeroMinuteLock_isNotActive() {
        // A 0-minute cooldown means the window has already elapsed — not locked.
        guard.recordFailure(store, 1, 0);
        assertFalse(guard.isLocked(store));
    }
}
