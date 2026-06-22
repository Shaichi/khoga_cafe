package com.khoga.voucher;

import com.khoga.common.model.Voucher;
import com.khoga.voucher.dto.VoucherResponse;

/** Hand-written entity→DTO mapper (project convention: no MapStruct). */
final class VoucherMapper {

    private VoucherMapper() {
    }

    static VoucherResponse toResponse(Voucher v, VoucherStatus status) {
        return new VoucherResponse(
                v.getId(), v.getCode(), v.getDiscountType(), v.getDiscountValue(),
                v.getMinOrderValue(), v.getStartDate(), v.getEndDate(), v.getMaxDiscountAmount(),
                v.getUsageLimitPerCustomer(), v.getMaxTotalUses(), v.getTotalUsageCount(), status);
    }
}
