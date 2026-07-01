package com.khoga.pos;

import com.khoga.common.dto.ApiResponse;
import com.khoga.pos.dto.VietQrCallbackRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import org.springframework.beans.factory.annotation.Value;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import com.khoga.common.exception.AppException;

import org.springframework.web.bind.annotation.RequestHeader;

/**
 * Payment gateway webhooks. The VietQR callback is public (permitAll in SecurityConfig) because the
 * gateway authenticates via HMAC signature, not a JWT (BR-84). Auto-confirm + late-callback guard
 * (BR-85) live in {@link CheckoutService#handleQrCallback}.
 */
@RestController
@RequestMapping("/api/v1/payments")
public class PaymentController {

    private final CheckoutService checkoutService;
    
    @Value("${app.vietqr.webhook-secret:dev-webhook-secret}")
    private String webhookSecret;

    public PaymentController(CheckoutService checkoutService) {
        this.checkoutService = checkoutService;
    }

    @PostMapping("/vietqr/callback")
    public ResponseEntity<ApiResponse<Void>> vietqrCallback(
            @RequestHeader(value = "x-api-validate", required = false) String signature,
            @RequestBody VietQrCallbackRequest req) {

        if (signature == null || signature.isEmpty()) {
            throw AppException.of("err.049"); // "Chữ ký Webhook không hợp lệ"
        }

        String payload = req.orderId().toString() + "|" + req.reference();
        String expected = generateMac(payload, webhookSecret);

        if (!expected.equals(signature)) {
            throw AppException.of("err.049");
        }

        checkoutService.handleQrCallback(req);
        return ResponseEntity.ok(ApiResponse.success(null, "Đã xử lý callback"));
    }

    private String generateMac(String payload, String secret) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            SecretKeySpec secretKeySpec = new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256");
            mac.init(secretKeySpec);
            byte[] hmacBytes = mac.doFinal(payload.getBytes(StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(hmacBytes);
        } catch (Exception e) {
            throw new RuntimeException("Failed to generate HMAC", e);
        }
    }
}
