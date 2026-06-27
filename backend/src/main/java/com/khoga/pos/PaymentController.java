package com.khoga.pos;

import com.khoga.common.dto.ApiResponse;
import com.khoga.pos.dto.VietQrCallbackRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Payment gateway webhooks. The VietQR callback is public (permitAll in SecurityConfig) because the
 * gateway authenticates via HMAC signature, not a JWT (BR-84). Auto-confirm + late-callback guard
 * (BR-85) live in {@link CheckoutService#handleQrCallback}.
 */
@RestController
@RequestMapping("/api/v1/payments")
public class PaymentController {

    private final CheckoutService checkoutService;

    public PaymentController(CheckoutService checkoutService) {
        this.checkoutService = checkoutService;
    }

    @PostMapping("/vietqr/callback")
    public ResponseEntity<ApiResponse<Void>> vietqrCallback(@Valid @RequestBody VietQrCallbackRequest req) {
        checkoutService.handleQrCallback(req);
        return ResponseEntity.ok(ApiResponse.success(null, "Đã xử lý callback"));
    }
}
