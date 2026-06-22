package com.khoga.voucher;

import com.khoga.audit.AuditLogService;
import com.khoga.common.exception.AppException;
import com.khoga.common.model.enums.DiscountType;
import com.khoga.common.repository.VoucherRepository;
import com.khoga.voucher.dto.CreateVoucherRequest;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/** P1.4 unit tests for voucher creation rules (BR-42 percentage cap requirement, unique code). */
@ExtendWith(MockitoExtension.class)
class VoucherServiceTest {

    @Mock private VoucherRepository voucherRepository;
    @Mock private AuditLogService auditLogService;
    private final VoucherStatusEngine statusEngine = new VoucherStatusEngine();

    private VoucherService service() {
        return new VoucherService(voucherRepository, statusEngine, auditLogService);
    }

    @Test
    void create_percentageWithoutCap_throws() {
        when(voucherRepository.existsByCodeIgnoreCase("SAVE10")).thenReturn(false);
        CreateVoucherRequest request = new CreateVoucherRequest(
                "SAVE10", DiscountType.PERCENTAGE, new BigDecimal("10"), null, null, null, null, null, null);

        assertThrows(AppException.class, () -> service().create(request, UUID.randomUUID()));
        verify(voucherRepository, never()).save(any());
    }

    @Test
    void create_duplicateCode_throws() {
        when(voucherRepository.existsByCodeIgnoreCase("SAVE10")).thenReturn(true);
        CreateVoucherRequest request = new CreateVoucherRequest(
                "SAVE10", DiscountType.FIXED_AMOUNT, new BigDecimal("5000"), null, null, null, null, null, null);

        assertThrows(AppException.class, () -> service().create(request, UUID.randomUUID()));
        verify(voucherRepository, never()).save(any());
    }

    @Test
    void create_validFixedAmount_saves() {
        when(voucherRepository.existsByCodeIgnoreCase("SAVE5K")).thenReturn(false);
        when(voucherRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        CreateVoucherRequest request = new CreateVoucherRequest(
                "SAVE5K", DiscountType.FIXED_AMOUNT, new BigDecimal("5000"), null, null, null, null, null, null);

        service().create(request, UUID.randomUUID());

        verify(voucherRepository).save(any());
        verify(auditLogService).record(any(), any(), any(), any(), any());
    }

    @Test
    void create_startDateAfterEndDate_throws() {
        when(voucherRepository.existsByCodeIgnoreCase("V1")).thenReturn(false);
        LocalDateTime start = LocalDateTime.of(2026, 7, 10, 0, 0);
        LocalDateTime end = LocalDateTime.of(2026, 7, 1, 0, 0); // end before start
        CreateVoucherRequest request = new CreateVoucherRequest(
                "V1", DiscountType.FIXED_AMOUNT, new BigDecimal("5000"), null, start, end, null, null, null);

        assertThrows(AppException.class, () -> service().create(request, UUID.randomUUID()));
        verify(voucherRepository, never()).save(any());
    }

    @Test
    void create_percentageValueZero_throws() {
        when(voucherRepository.existsByCodeIgnoreCase("V2")).thenReturn(false);
        CreateVoucherRequest request = new CreateVoucherRequest(
                "V2", DiscountType.PERCENTAGE, BigDecimal.ZERO, null, null, null, new BigDecimal("5000"), null, null);

        assertThrows(AppException.class, () -> service().create(request, UUID.randomUUID()));
        verify(voucherRepository, never()).save(any());
    }
}
