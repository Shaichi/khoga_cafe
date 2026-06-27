package com.khoga.pos;

import com.khoga.auth.SecurityUtil;
import com.khoga.common.dto.ApiResponse;
import com.khoga.pos.dto.CheckoutRequest;
import com.khoga.pos.dto.CheckoutResponse;
import com.khoga.pos.dto.DiscountBreakdown;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** POS checkout (UC-48/49/50/51). Cashier operates; Store Manager may override. */
@RestController
@RequestMapping("/api/v1/checkout")
@PreAuthorize("hasAnyRole('CASHIER','STORE_MANAGER')")
public class CheckoutController {

    private final CheckoutService checkoutService;

    public CheckoutController(CheckoutService checkoutService) {
        this.checkoutService = checkoutService;
    }

    /** UC-48/49 — preview the discount/tax breakdown for the current cart (no order created). */
    @PostMapping("/preview")
    public ResponseEntity<ApiResponse<DiscountBreakdown>> preview(@Valid @RequestBody CheckoutRequest req) {
        DiscountBreakdown b = checkoutService.preview(req, SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(b));
    }

    /** UC-51 — submit the order and take payment. */
    @PostMapping
    public ResponseEntity<ApiResponse<CheckoutResponse>> checkout(@Valid @RequestBody CheckoutRequest req) {
        CheckoutResponse res = checkoutService.submitOrder(req, SecurityUtil.currentUserId());
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(res, "Tạo đơn thành công"));
    }
}
