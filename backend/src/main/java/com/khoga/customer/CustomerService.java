package com.khoga.customer;

import com.khoga.audit.AuditLogService;
import com.khoga.common.exception.AppException;
import com.khoga.common.exception.ResourceNotFoundException;
import com.khoga.common.model.Customer;
import com.khoga.common.model.enums.ActionType;
import com.khoga.common.repository.CustomerRepository;
import com.khoga.common.repository.OrderRepository;
import com.khoga.customer.dto.CreateCustomerRequest;
import com.khoga.customer.dto.CustomerOrderEntry;
import com.khoga.customer.dto.CustomerResponse;
import com.khoga.customer.dto.PointAdjustmentRequest;
import com.khoga.customer.dto.UpdateCustomerRequest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Customer/loyalty master data (UC-24/25/26/27). Enrolment requires PDPA consent (BR-71); manual
 * point adjustments require a reason and are audited (BR-49).
 */
@Service
public class CustomerService {

    private final CustomerRepository customerRepository;
    private final OrderRepository orderRepository;
    private final AuditLogService auditLogService;

    public CustomerService(CustomerRepository customerRepository, OrderRepository orderRepository,
                           AuditLogService auditLogService) {
        this.customerRepository = customerRepository;
        this.orderRepository = orderRepository;
        this.auditLogService = auditLogService;
    }

    @Transactional(readOnly = true)
    public Page<CustomerResponse> list(String search, Pageable pageable) {
        Page<Customer> page = StringUtils.hasText(search)
                ? customerRepository.findByPhoneContainingOrFullNameContainingIgnoreCase(search, search, pageable)
                : customerRepository.findAll(pageable);
        return page.map(CustomerMapper::toResponse);
    }

    @Transactional(readOnly = true)
    public CustomerResponse get(UUID id) {
        return CustomerMapper.toResponse(load(id));
    }

    @Transactional(readOnly = true)
    public List<CustomerOrderEntry> history(UUID id) {
        load(id);
        return orderRepository.findTop50ByCustomerIdOrderByCreatedAtDesc(id).stream()
                .map(CustomerMapper::toOrderEntry).toList();
    }

    @Transactional
    public CustomerResponse create(CreateCustomerRequest request, UUID actorId) {
        if (customerRepository.existsByPhone(request.phone())) {
            throw new AppException("Số điện thoại đã tồn tại");
        }
        Customer customer = new Customer();
        customer.setPhone(request.phone());
        customer.setFullName(request.fullName());
        customer.setEmail(request.email());
        customer.setBirthDate(request.birthDate());
        customer.setIsActive(true);
        customer.setPoints(0);
        customer.setConsentVersion(request.consentVersion());     // BR-71
        customer.setConsentAt(LocalDateTime.now());
        Customer saved = customerRepository.save(customer);
        auditLogService.record(ActionType.CREATE, "Customer", null,
                "{\"phone\":\"" + request.phone() + "\"}", actorId);
        return CustomerMapper.toResponse(saved);
    }

    @Transactional
    public CustomerResponse update(UUID id, UpdateCustomerRequest request, UUID actorId) {
        Customer customer = load(id);
        if (StringUtils.hasText(request.fullName())) {
            customer.setFullName(request.fullName());
        }
        if (StringUtils.hasText(request.email())) {
            customer.setEmail(request.email());
        }
        if (request.birthDate() != null) {
            customer.setBirthDate(request.birthDate());
        }
        customerRepository.save(customer);
        auditLogService.record(ActionType.UPDATE, "Customer", null, "{\"id\":\"" + id + "\"}", actorId);
        return CustomerMapper.toResponse(customer);
    }

    /** UC-26 / BR-49: manual point adjustment — reason mandatory, audited, never drives points negative. */
    @Transactional
    public CustomerResponse adjustPoints(UUID id, PointAdjustmentRequest request, UUID actorId) {
        Customer customer = load(id);
        int current = customer.getPoints() == null ? 0 : customer.getPoints();
        int updated = current + request.delta();
        if (updated < 0) {
            throw new AppException("Số điểm sau điều chỉnh không được âm");
        }
        customer.setPoints(updated);
        customerRepository.save(customer);
        String reason = request.reason().replace("\"", "'");
        auditLogService.record(ActionType.UPDATE, "Customer",
                "{\"points\":" + current + "}",
                "{\"points\":" + updated + ",\"reason\":\"" + reason + "\"}", actorId);
        return CustomerMapper.toResponse(customer);
    }

    private Customer load(UUID id) {
        return customerRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy khách hàng"));
    }
}
