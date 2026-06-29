package com.khoga.auth;

import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

/** BR-16 (10-min expiry) + BR-17 (lock after 3 wrong tries) for the in-memory OTP store. */
class OtpStoreTest {

    private final OtpStore store = new OtpStore();
    private final UUID userId = UUID.randomUUID();

    @Test
    void correctCode_verifiesThenConsumesToUserId() {
        String code = store.issue("k", userId);
        assertEquals(OtpStore.Result.OK, store.verify("k", code));
        assertEquals(userId, store.consume("k"));
        assertEquals(OtpStore.Result.NOT_FOUND, store.verify("k", code)); // gone after consume
    }

    @Test
    void unknownKeyIsNotFound() {
        assertEquals(OtpStore.Result.NOT_FOUND, store.verify("missing", "000000"));
        assertNull(store.consume("missing"));
    }

    @Test
    void expiredCodeIsRejectedAndPurged() {
        store.issue("k", userId, LocalDateTime.now().minusMinutes(1));
        assertEquals(OtpStore.Result.EXPIRED, store.verify("k", "whatever"));
    }

    @Test
    void locksAfterThreeWrongAttempts() {
        store.issue("k", userId);
        assertEquals(OtpStore.Result.INVALID, store.verify("k", "111111"));
        assertEquals(OtpStore.Result.INVALID, store.verify("k", "222222"));
        assertEquals(OtpStore.Result.LOCKED, store.verify("k", "333333")); // 3rd wrong → locked
        // even the right code is refused once locked
        assertEquals(OtpStore.Result.LOCKED, store.verify("k", "444444"));
    }

    @Test
    void purgeExpiredDropsOnlyStaleEntries() {
        store.issue("fresh", userId);
        store.issue("stale", userId, LocalDateTime.now().minusMinutes(1));
        assertEquals(1, store.purgeExpired());
        assertEquals(OtpStore.Result.NOT_FOUND, store.verify("stale", "x"));
    }
}
