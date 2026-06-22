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
        if (!Boolean.TRUE.equals(voucher.getIsActive())) {
            return VoucherStatus.INACTIVE;
        }
        if (voucher.getStartDate() != null && now.isBefore(voucher.getStartDate())) {
            return VoucherStatus.SCHEDULED;
        }
        if (voucher.getEndDate() != null && now.isAfter(voucher.getEndDate())) {
            return VoucherStatus.EXPIRED;
        }
        if (voucher.getMaxTotalUses() != null && voucher.getTotalUsageCount() != null
                && voucher.getTotalUsageCount() >= voucher.getMaxTotalUses()) {
            return VoucherStatus.EXPIRED;
        }
        return VoucherStatus.ACTIVE;
    }

    public VoucherStatus status(Voucher voucher) {
        return statusAt(voucher, LocalDateTime.now());
    }
}
