package com.khoga.common.i18n;

import org.springframework.context.MessageSource;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.stereotype.Component;

/**
 * Thin facade over Spring's {@link MessageSource} that resolves a message code against the
 * <em>current request locale</em> ({@link LocaleContextHolder}, populated by the configured
 * {@code LocaleResolver}). If the code is unknown the code itself is returned, so a missing
 * translation degrades gracefully instead of throwing.
 *
 * <p>Used by {@code GlobalExceptionHandler} (and any controller that wants localized text) so call
 * sites stay terse: {@code messages.get("MSG16", max)}.
 */
@Component
public class Messages {

    private final MessageSource messageSource;

    public Messages(MessageSource messageSource) {
        this.messageSource = messageSource;
    }

    public String get(String code, Object... args) {
        return messageSource.getMessage(code, args, code, LocaleContextHolder.getLocale());
    }
}
