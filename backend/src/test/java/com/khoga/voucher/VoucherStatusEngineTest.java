package com.khoga.voucher;

import com.khoga.common.model.Voucher;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.assertEquals;

/** P1.4 unit tests for BR-52 derived voucher status. */
class VoucherStatusEngineTest {

    private final VoucherStatusEngine engine = new VoucherStatusEngine();
    private final LocalDateTime now = LocalDateTime.of(2026, 6, 22, 12, 0);

    private Voucher voucher(boolean active, LocalDateTime start, LocalDateTime end) {
        Voucher v = new Voucher();
        v.setIsActive(active);
        v.setStartDate(start);
        v.setEndDate(end);
        v.setTotalUsageCount(0);
        return v;
    }

    @Test
    void deactivatedFoldsIntoExpired() {
        // RDS §3.4.3: deactivation is terminal → EXPIRED (no separate INACTIVE state).
        assertEquals(VoucherStatus.EXPIRED, engine.statusAt(voucher(false, null, null), now));
    }

    @Test
    void beforeStartIsScheduled() {
        assertEquals(VoucherStatus.SCHEDULED, engine.statusAt(voucher(true, now.plusDays(1), null), now));
    }

    @Test
    void afterEndIsExpired() {
        assertEquals(VoucherStatus.EXPIRED, engine.statusAt(voucher(true, now.minusDays(2), now.minusDays(1)), now));
    }

    @Test
    void withinWindowIsActive() {
        assertEquals(VoucherStatus.ACTIVE, engine.statusAt(voucher(true, now.minusDays(1), now.plusDays(1)), now));
    }

    @Test
    void usageCapReachedStaysActive() {
        // RDS §3.4.3: exhaustion doesn't change status; it only blocks further redemptions.
        Voucher v = voucher(true, now.minusDays(1), now.plusDays(1));
        v.setMaxTotalUses(5);
        v.setTotalUsageCount(5);
        assertEquals(VoucherStatus.ACTIVE, engine.statusAt(v, now));
    }
}
