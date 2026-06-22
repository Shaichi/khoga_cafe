package com.khoga.integration;

import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;

/**
 * Dev/test email adapter — logs instead of sending. Active on every profile except {@code prod}.
 */
@Slf4j
@Service
@Profile("!prod")
public class EmailServiceStub implements EmailService {

    @Override
    public void send(String to, String subject, String body) {
        log.info("[EMAIL-STUB] to={} | subject='{}' | body='{}'", to, subject, body);
    }
}
