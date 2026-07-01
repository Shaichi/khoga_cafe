package com.khoga.pos;

import com.khoga.common.dto.ApiResponse;
import com.khoga.common.exception.AppException;
import com.khoga.integration.VietQrClient;
import com.khoga.pos.dto.VietQrCallbackRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Payment gateway webhooks. The VietQR callback is public (permitAll in SecurityConfig) because the
 * gateway authenticates via HMAC signature, not a JWT (BR-84). Signature verification is delegated to
 * {@link VietQrClient#verifyWebhookSignature} (RDS §3.7.4); auto-confirm + late-callback guard (BR-85)
 * and idempotency live in {@link CheckoutService#handleQrCallback}.
 */
@RestController
@RequestMapping("/api/v1/payments")
public class PaymentController {

    private final CheckoutService checkoutService;
    private final VietQrClient vietQrClient;

    public PaymentController(CheckoutService checkoutService, VietQrClient vietQrClient) {
        this.checkoutService = checkoutService;
        this.vietQrClient = vietQrClient;
    }

    @PostMapping("/vietqr/callback")
    public ResponseEntity<ApiResponse<Void>> vietqrCallback(
            @RequestHeader(value = "x-api-validate", required = false) String signature,
            @RequestBody VietQrCallbackRequest req) {
        String payload = req.orderId().toString() + "|" + req.reference();
        if (!vietQrClient.verifyWebhookSignature(payload, signature)) {
            throw AppException.of("err.049"); // "Chữ ký Webhook không hợp lệ"
        }
        checkoutService.handleQrCallback(req);
        return ResponseEntity.ok(ApiResponse.success(null, "Đã xử lý callback"));
    }
}
