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
    public ResponseEntity<ApiResponse<Void>> vietqrCallback(@Valid @RequestBody VietQrCallbackRequest req) {
        // BR-47: Validate HMAC Signature
        if (req.signature() == null || !isValidSignature(req.orderId().toString(), req.reference(), req.signature())) {
            throw AppException.of("err.049");
        }
        
        checkoutService.handleQrCallback(req);
        return ResponseEntity.ok(ApiResponse.success(null, "Đã xử lý callback"));
    }

    private boolean isValidSignature(String orderId, String reference, String signature) {
        try {
            String payload = orderId + "|" + reference;
            Mac mac = Mac.getInstance("HmacSHA256");
            SecretKeySpec secretKeySpec = new SecretKeySpec(webhookSecret.getBytes(StandardCharsets.UTF_8), "HmacSHA256");
            mac.init(secretKeySpec);
            byte[] hmacBytes = mac.doFinal(payload.getBytes(StandardCharsets.UTF_8));
            String expectedSignature = Base64.getEncoder().encodeToString(hmacBytes);
            return expectedSignature.equals(signature);
        } catch (Exception e) {
            return false;
        }
    }
}
