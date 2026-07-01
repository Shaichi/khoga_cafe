package com.khoga.auth;

import com.khoga.common.model.OtpEntity;
import com.khoga.common.repository.OtpRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.stubbing.Answer;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class OtpStoreTest {

    private OtpRepository otpRepository = mock(OtpRepository.class);
    private OtpStore store;
    private final UUID userId = UUID.randomUUID();
    private Map<String, OtpEntity> dbMap = new HashMap<>();

    @BeforeEach
    void setUp() {
        store = new OtpStore(otpRepository);
        dbMap.clear();

        when(otpRepository.findById(any())).thenAnswer(invocation -> {
            String id = invocation.getArgument(0);
            return Optional.ofNullable(dbMap.get(id));
        });

        when(otpRepository.save(any())).thenAnswer(invocation -> {
            OtpEntity entity = invocation.getArgument(0);
            dbMap.put(entity.getId(), entity);
            return entity;
        });

        doAnswer(invocation -> {
            String id = invocation.getArgument(0);
            dbMap.remove(id);
            return null;
        }).when(otpRepository).deleteById(any());
    }

    @Test
    void correctCode_verifiesThenConsumesToUserId() {
        String code = store.issue("k", userId);
        assertEquals(OtpStore.Result.OK, store.verify("k", code));
        assertEquals(userId, store.consume("k"));
        assertEquals(OtpStore.Result.NOT_FOUND, store.verify("k", code));
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
        assertNull(dbMap.get("k"));
    }

    @Test
    void locksAfterThreeWrongAttempts() {
        String code = store.issue("k", userId);
        assertEquals(OtpStore.Result.INVALID, store.verify("k", "111111"));
        assertEquals(OtpStore.Result.INVALID, store.verify("k", "222222"));
        assertEquals(OtpStore.Result.LOCKED, store.verify("k", "333333"));
        assertEquals(OtpStore.Result.LOCKED, store.verify("k", code));
    }
}
