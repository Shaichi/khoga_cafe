package com.khoga.voucher;

import com.khoga.audit.AuditLogService;
import com.khoga.common.exception.AppException;
import com.khoga.common.exception.ResourceNotFoundException;
import com.khoga.common.model.Voucher;
import com.khoga.common.model.enums.ActionType;
import com.khoga.common.model.enums.DiscountType;
import com.khoga.common.repository.VoucherRepository;
import com.khoga.voucher.dto.CreateVoucherRequest;
import com.khoga.voucher.dto.UpdateVoucherRequest;
import com.khoga.voucher.dto.VoucherResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Voucher management (UC-20/21/22/23). The {@code code} is immutable after creation; percentage
 * vouchers must carry a max-discount cap (BR-42); deactivation halts redemption immediately (BR-41);
 * changes are audited (BR-68). Displayed status is derived by {@link VoucherStatusEngine} (BR-52).
 */
@Service
public class VoucherService {

    private final VoucherRepository voucherRepository;
    private final VoucherStatusEngine statusEngine;
    private final AuditLogService auditLogService;

    public VoucherService(VoucherRepository voucherRepository, VoucherStatusEngine statusEngine,
                          AuditLogService auditLogService) {
        this.voucherRepository = voucherRepository;
        this.statusEngine = statusEngine;
        this.auditLogService = auditLogService;
    }

    @Transactional(readOnly = true)
    public Page<VoucherResponse> list(Pageable pageable) {
        return voucherRepository.findAll(pageable)
                .map(v -> VoucherMapper.toResponse(v, statusEngine.status(v)));
    }

    @Transactional(readOnly = true)
    public VoucherResponse get(UUID id) {
        Voucher voucher = load(id);
        return VoucherMapper.toResponse(voucher, statusEngine.status(voucher));
    }

    @Transactional
    public VoucherResponse create(CreateVoucherRequest request, UUID actorId) {
        if (voucherRepository.existsByCodeIgnoreCase(request.code())) {
            throw new AppException("Mã voucher đã tồn tại");
        }
        validateDateRange(request.startDate(), request.endDate());
        validateDiscountShape(request.discountType(), request.discountValue(), request.maxDiscountAmount());

        Voucher voucher = new Voucher();
        voucher.setCode(request.code());
        voucher.setDiscountType(request.discountType());
        voucher.setDiscountValue(request.discountValue());
        voucher.setMinOrderValue(request.minOrderValue());
        voucher.setStartDate(request.startDate());
        voucher.setEndDate(request.endDate());
        voucher.setMaxDiscountAmount(request.maxDiscountAmount());
        voucher.setUsageLimitPerCustomer(request.usageLimitPerCustomer());
        voucher.setMaxTotalUses(request.maxTotalUses());
        voucher.setTotalUsageCount(0);
        voucher.setIsActive(true);
        Voucher saved = voucherRepository.save(voucher);
        auditLogService.record(ActionType.CREATE, "Voucher", null,
                "{\"code\":\"" + request.code() + "\"}", actorId);
        return VoucherMapper.toResponse(saved, statusEngine.status(saved));
    }

    @Transactional
    public VoucherResponse update(UUID id, UpdateVoucherRequest request, UUID actorId) {
        Voucher voucher = load(id);
        validateDateRange(request.startDate(), request.endDate());
        validateDiscountShape(request.discountType(), request.discountValue(), request.maxDiscountAmount());
        voucher.setDiscountType(request.discountType());
        voucher.setDiscountValue(request.discountValue());
        voucher.setMinOrderValue(request.minOrderValue());
        voucher.setStartDate(request.startDate());
        voucher.setEndDate(request.endDate());
        voucher.setMaxDiscountAmount(request.maxDiscountAmount());
        voucher.setUsageLimitPerCustomer(request.usageLimitPerCustomer());
        voucher.setMaxTotalUses(request.maxTotalUses());
        if (request.active() != null) {
            voucher.setIsActive(request.active());
        }
        voucherRepository.save(voucher);
        auditLogService.record(ActionType.UPDATE, "Voucher", null, "{\"id\":\"" + id + "\"}", actorId);
        return VoucherMapper.toResponse(voucher, statusEngine.status(voucher));
    }

    /** UC-23 / BR-41: deactivation stops all redemptions at once. */
    @Transactional
    public void deactivate(UUID id, UUID actorId) {
        Voucher voucher = load(id);
        voucher.setIsActive(false);
        voucherRepository.save(voucher);
        auditLogService.record(ActionType.UPDATE, "Voucher", null, "{\"event\":\"DEACTIVATE\"}", actorId);
    }

    private void validateDateRange(LocalDateTime start, LocalDateTime end) {
        if (start != null && end != null && !start.isBefore(end)) {
            throw new AppException("Ngày bắt đầu phải trước ngày kết thúc");
        }
    }

    private void validateDiscountShape(DiscountType type, BigDecimal value, BigDecimal maxDiscountAmount) {
        if (type == DiscountType.PERCENTAGE) {
            if (maxDiscountAmount == null) {
                throw new AppException("Voucher giảm theo phần trăm phải có mức giảm tối đa");   // BR-42
            }
            if (value != null && (value.compareTo(BigDecimal.ONE) < 0 || value.compareTo(BigDecimal.valueOf(100)) > 0)) {
                throw new AppException("Phần trăm giảm phải từ 1 đến 100");
            }
        }
    }

    private Voucher load(UUID id) {
        return voucherRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy voucher"));
    }
}
