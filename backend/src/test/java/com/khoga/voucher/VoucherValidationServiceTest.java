package com.khoga.voucher;

import com.khoga.common.exception.AppException;
import com.khoga.common.model.Voucher;
import com.khoga.common.model.enums.DiscountType;
import com.khoga.common.repository.VoucherRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.when;

/** P1.4 unit tests for checkout voucher validation + discount math (BR-42/BR-50). */
@ExtendWith(MockitoExtension.class)
class VoucherValidationServiceTest {

    @Mock private VoucherRepository voucherRepository;
    private final VoucherStatusEngine statusEngine = new VoucherStatusEngine();
    private VoucherValidationService service() {
        return new VoucherValidationService(voucherRepository, statusEngine);
    }

    private Voucher activePercentage(BigDecimal value, BigDecimal cap) {
        Voucher v = new Voucher();
        v.setCode("SAVE10");
        v.setDiscountType(DiscountType.PERCENTAGE);
        v.setDiscountValue(value);
        v.setMaxDiscountAmount(cap);
        v.setIsActive(true);
        v.setStartDate(LocalDateTime.now().minusDays(1));
        v.setEndDate(LocalDateTime.now().plusDays(1));
        v.setTotalUsageCount(0);
        return v;
    }

    @Test
    void percentageDiscountIsCappedByMaxAmount() {
        when(voucherRepository.findByCode("SAVE10"))
                .thenReturn(Optional.of(activePercentage(new BigDecimal("10"), new BigDecimal("8000"))));
        // 10% of 100,000 = 10,000 but capped at 8,000
        assertEquals(0, service().validate("SAVE10", new BigDecimal("100000"), 0).compareTo(new BigDecimal("8000")));
    }

    @Test
    void percentageDiscountUncappedComputesNormally() {
        when(voucherRepository.findByCode("SAVE10"))
                .thenReturn(Optional.of(activePercentage(new BigDecimal("10"), new BigDecimal("50000"))));
        assertEquals(0, service().validate("SAVE10", new BigDecimal("100000"), 0).compareTo(new BigDecimal("10000")));
    }

    @Test
    void belowMinOrderValueThrows() {
        Voucher v = activePercentage(new BigDecimal("10"), new BigDecimal("8000"));
        v.setMinOrderValue(new BigDecimal("50000"));
        when(voucherRepository.findByCode("SAVE10")).thenReturn(Optional.of(v));
        assertThrows(AppException.class, () -> service().validate("SAVE10", new BigDecimal("20000"), 0));
    }

    @Test
    void perCustomerLimitReachedThrows() {
        Voucher v = activePercentage(new BigDecimal("10"), new BigDecimal("8000"));
        v.setUsageLimitPerCustomer(1);
        when(voucherRepository.findByCode("SAVE10")).thenReturn(Optional.of(v));
        assertThrows(AppException.class, () -> service().validate("SAVE10", new BigDecimal("100000"), 1));
    }

    @Test
    void unknownCodeThrows() {
        when(voucherRepository.findByCode("NOPE")).thenReturn(Optional.empty());
        assertThrows(AppException.class, () -> service().validate("NOPE", new BigDecimal("100000"), 0));
    }

    @Test
    void deactivatedVoucherBlocksValidation() {
        Voucher v = activePercentage(new BigDecimal("10"), new BigDecimal("50000"));
        v.setIsActive(false); // deactivated
        when(voucherRepository.findByCode("SAVE10")).thenReturn(Optional.of(v));
        assertThrows(AppException.class, () -> service().validate("SAVE10", new BigDecimal("100000"), 0));
    }

    @Test
    void fixedAmountDiscountCappedAtSubtotal() {
        Voucher v = new Voucher();
        v.setCode("BIG");
        v.setDiscountType(DiscountType.FIXED_AMOUNT);
        v.setDiscountValue(new BigDecimal("50000")); // discount bigger than order
        v.setIsActive(true);
        v.setStartDate(LocalDateTime.now().minusDays(1));
        v.setEndDate(LocalDateTime.now().plusDays(1));
        v.setTotalUsageCount(0);
        when(voucherRepository.findByCode("BIG")).thenReturn(Optional.of(v));

        BigDecimal discount = service().validate("BIG", new BigDecimal("30000"), 0);
        // BR-50: discount should be capped at the subtotal of 30,000
        assertEquals(0, discount.compareTo(new BigDecimal("30000")));
    }

    @Test
    void maxTotalUsesReachedBlocksValidation() {
        Voucher v = activePercentage(new BigDecimal("10"), new BigDecimal("50000"));
        v.setMaxTotalUses(100);
        v.setTotalUsageCount(100); // exhausted
        when(voucherRepository.findByCode("SAVE10")).thenReturn(Optional.of(v));
        // Should be EXPIRED via VoucherStatusEngine → rejected by validation
        assertThrows(AppException.class, () -> service().validate("SAVE10", new BigDecimal("100000"), 0));
    }
}
