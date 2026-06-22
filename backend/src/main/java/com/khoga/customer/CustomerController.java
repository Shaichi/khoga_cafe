package com.khoga.customer;

import com.khoga.auth.SecurityUtil;
import com.khoga.common.dto.ApiResponse;
import com.khoga.common.dto.PageResponse;
import com.khoga.customer.dto.CreateCustomerRequest;
import com.khoga.customer.dto.CustomerOrderEntry;
import com.khoga.customer.dto.CustomerResponse;
import com.khoga.customer.dto.PointAdjustmentRequest;
import com.khoga.customer.dto.UpdateCustomerRequest;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * Customer/loyalty endpoints (UC-24/25/26/27). Lookup/enrol/update are open to authenticated staff
 * (cashiers enrol at the POS); manual point adjustment is HQ-only (BR-49).
 */
@RestController
@RequestMapping("/api/v1/customers")
public class CustomerController {

    private final CustomerService customerService;

    public CustomerController(CustomerService customerService) {
        this.customerService = customerService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<CustomerResponse>>> list(
            @RequestParam(required = false) String search,
            @PageableDefault(size = 20) Pageable pageable) {
        Page<CustomerResponse> page = customerService.list(search, pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.of(page)));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<CustomerResponse>> get(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.success(customerService.get(id)));
    }

    @GetMapping("/{id}/history")
    public ResponseEntity<ApiResponse<List<CustomerOrderEntry>>> history(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.success(customerService.history(id)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<CustomerResponse>> create(@Valid @RequestBody CreateCustomerRequest request) {
        CustomerResponse created = customerService.create(request, SecurityUtil.currentUserId());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(created, "Tạo khách hàng thành công"));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<CustomerResponse>> update(
            @PathVariable UUID id, @Valid @RequestBody UpdateCustomerRequest request) {
        CustomerResponse updated = customerService.update(id, request, SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(updated, "Cập nhật khách hàng thành công"));
    }

    @PostMapping("/{id}/points")
    @PreAuthorize("hasRole('SSADMIN')")
    public ResponseEntity<ApiResponse<CustomerResponse>> adjustPoints(
            @PathVariable UUID id, @Valid @RequestBody PointAdjustmentRequest request) {
        CustomerResponse updated = customerService.adjustPoints(id, request, SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(updated, "Điều chỉnh điểm thành công"));
    }
}
