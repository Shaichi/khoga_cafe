package com.khoga.voucher;

import com.khoga.common.model.Voucher;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

/**
 * Computes a voucher's lifecycle status (BR-52) from its active flag, validity window and usage cap.
 * The {@code now}-taking overload keeps the logic deterministic for tests.
 */
@Component
public class VoucherStatusEngine {

    public VoucherStatus statusAt(Voucher voucher, LocalDateTime now) {
        // Deactivation is terminal and folds into EXPIRED (RDS §3.4.3 — no separate INACTIVE state).
        if (!Boolean.TRUE.equals(voucher.getIsActive())) {
            return VoucherStatus.EXPIRED;
        }
        if (voucher.getStartDate() != null && now.isBefore(voucher.getStartDate())) {
            return VoucherStatus.SCHEDULED;
        }
        if (voucher.getEndDate() != null && now.isAfter(voucher.getEndDate())) {
            return VoucherStatus.EXPIRED;
        }
        // Usage exhaustion (totalUsageCount >= maxTotalUses) does NOT change status — it stays ACTIVE;
        // the cap only blocks further redemptions (enforced in VoucherValidationService, BR-52).
        return VoucherStatus.ACTIVE;
    }

    public VoucherStatus status(Voucher voucher) {
        return statusAt(voucher, LocalDateTime.now());
    }
}
