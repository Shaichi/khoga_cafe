package com.khoga.integration;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Slf4j
@Service
public class RealEmailService implements EmailService {

    private final JavaMailSender mailSender;
    private final String fromEmail;

    public RealEmailService(JavaMailSender mailSender, 
                            @Value("${spring.mail.username:noreply@khoga.com}") String fromEmail) {
        this.mailSender = mailSender;
        this.fromEmail = fromEmail;
    }

    @Override
    public void send(String to, String subject, String body) {
        // Log to console for development/QA review of OTPs and notifications
        log.info("[EMAIL-DEBUG] Destination: {}, Subject: {}, Body: {}", to, subject, body);
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromEmail);
            message.setTo(to);
            message.setSubject(subject);
            message.setText(body);
            mailSender.send(message);
            log.info("[EMAIL] Sent email to {}", to);
        } catch (Exception e) {
            log.error("[EMAIL] Failed to send email to {} (Dummy password is set in .env; please read [EMAIL-DEBUG] above for the OTP code)", to, e);
        }
    }

}
