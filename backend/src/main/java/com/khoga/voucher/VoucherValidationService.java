package com.khoga.voucher;

import com.khoga.common.exception.AppException;
import com.khoga.common.model.Voucher;
import com.khoga.common.model.enums.DiscountType;
import com.khoga.common.repository.VoucherRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Reusable voucher validation + discount computation for checkout (UC-48). Enforces ACTIVE status
 * (BR-52), minimum order value, per-customer usage limit, and caps the percentage discount by
 * {@code maxDiscountAmount} (BR-42); the discount can never exceed the subtotal (BR-50).
 */
@Service
public class VoucherValidationService {

    private final VoucherRepository voucherRepository;
    private final VoucherStatusEngine statusEngine;

    public VoucherValidationService(VoucherRepository voucherRepository, VoucherStatusEngine statusEngine) {
        this.voucherRepository = voucherRepository;
        this.statusEngine = statusEngine;
    }

    /**
     * @param code               the voucher code entered at checkout
     * @param orderSubtotal      gross subtotal the voucher applies to
     * @param customerUsageCount how many times this customer has already used the voucher
     * @return the discount amount (≥ 0, ≤ subtotal)
     */
    @Transactional(readOnly = true)
    public BigDecimal validate(String code, BigDecimal orderSubtotal, int customerUsageCount) {
        Voucher voucher = voucherRepository.findByCode(code)
                .orElseThrow(() -> AppException.of("MSG09"));           // invalid / not found
        if (statusEngine.status(voucher) != VoucherStatus.ACTIVE) {
            throw AppException.of("MSG09");                              // scheduled / expired / deactivated
        }
        // BR-52: usage exhaustion keeps the voucher ACTIVE but blocks further redemption (the cap is an
        // explicit gate here, not a status change — see VoucherStatusEngine / RDS §3.4.3).
        if (voucher.getMaxTotalUses() != null && voucher.getTotalUsageCount() != null
                && voucher.getTotalUsageCount() >= voucher.getMaxTotalUses()) {
            throw AppException.of("MSG09");
        }
        if (voucher.getMinOrderValue() != null && orderSubtotal.compareTo(voucher.getMinOrderValue()) < 0) {
            throw AppException.of("err.088");
        }
        if (voucher.getUsageLimitPerCustomer() != null
                && customerUsageCount >= voucher.getUsageLimitPerCustomer()) {
            throw AppException.of("err.089");
        }
        return computeDiscount(voucher, orderSubtotal);
    }

    public BigDecimal computeDiscount(Voucher voucher, BigDecimal subtotal) {
        BigDecimal discount;
        if (voucher.getDiscountType() == DiscountType.PERCENTAGE) {
            discount = subtotal.multiply(voucher.getDiscountValue())
                    .divide(BigDecimal.valueOf(100), 0, RoundingMode.HALF_UP);
            if (voucher.getMaxDiscountAmount() != null
                    && discount.compareTo(voucher.getMaxDiscountAmount()) > 0) {
                discount = voucher.getMaxDiscountAmount();                       // BR-42 cap
            }
        } else {
            discount = voucher.getDiscountValue();
        }
        if (discount.compareTo(subtotal) > 0) {
            discount = subtotal;                                                 // never exceed subtotal (BR-50)
        }
        return discount;
    }
}
