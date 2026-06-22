package com.khoga.integration;

/**
 * Outbound email port. The default {@link EmailServiceStub} logs to the console; a real
 * {@code SmtpEmailService} (P4) will replace it under the {@code prod} profile.
 */
public interface EmailService {

    void send(String to, String subject, String body);
}
