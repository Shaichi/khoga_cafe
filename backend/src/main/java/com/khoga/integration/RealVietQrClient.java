package com.khoga.integration;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Slf4j
@Service
public class RealVietQrClient implements VietQrClient {

    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${app.vietqr.webhook-secret:dev-webhook-secret}")
    private String webhookSecret;

    @Value("${app.vietqr.client-id:}")
    private String clientId;

    @Value("${app.vietqr.api-key:}")
    private String apiKey;

    @Value("${app.vietqr.bank-id:970415}") // Example: VietinBank
    private String bankId;

    @Value("${app.vietqr.account-no:113366668888}")
    private String accountNo;
    
    @Value("${app.vietqr.account-name:KHOGA CAFE}")
    private String accountName;

    @Override
    public VietQrPayment generateQr(UUID orderId, BigDecimal amount) {
        String reference = "KHOGA-" + orderId;
        
        try {
            String url = "https://api.vietqr.io/v2/generate";
            
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("x-client-id", clientId);
            headers.set("x-api-key", apiKey);

            Map<String, Object> request = new HashMap<>();
            request.put("accountNo", accountNo);
            request.put("accountName", accountName);
            request.put("acqId", bankId);
            request.put("addInfo", reference);
            request.put("amount", amount.intValue());
            request.put("template", "compact");

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(request, headers);
            
            ResponseEntity<Map> response = restTemplate.postForEntity(url, entity, Map.class);
            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                Map<String, Object> data = (Map<String, Object>) response.getBody().get("data");
                if (data != null && data.containsKey("qrDataURL")) {
                    String qrContent = (String) data.get("qrDataURL");
                    log.info("[VIETQR] Generated QR for order={}, amount={}, ref={}", orderId, amount, reference);
                    return new VietQrPayment(orderId, amount, qrContent, reference);
                }
            }
        } catch (Exception e) {
            log.error("[VIETQR] Failed to generate QR from VietQR API for order={}, ref={}", orderId, reference, e);
        }
        
        // Fallback to basic string if API fails
        String fallbackQr = "00020101021238" + reference + "5303704" + amount;
        return new VietQrPayment(orderId, amount, fallbackQr, reference);
    }

    @Override
    public boolean verifyWebhookSignature(String payload, String signature) {
        if (signature == null || signature.isEmpty() || payload == null) {
            return false;
        }
        return generateMac(payload, webhookSecret).equals(signature);
    }

    private String generateMac(String payload, String secret) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            byte[] hmacBytes = mac.doFinal(payload.getBytes(StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(hmacBytes);
        } catch (Exception e) {
            throw new RuntimeException("Failed to generate HMAC", e);
        }
    }
}
