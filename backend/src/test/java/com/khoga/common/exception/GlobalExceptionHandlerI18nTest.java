package com.khoga.common.exception;

import com.khoga.common.dto.ApiResponse;
import com.khoga.common.i18n.Messages;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.context.i18n.LocaleContextHolder;
import org.springframework.context.support.ResourceBundleMessageSource;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import java.util.Locale;

import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * P4 i18n — the global handler localizes coded exceptions against the request locale while passing
 * legacy literal messages through unchanged, and never leaks internal detail on a 500.
 */
class GlobalExceptionHandlerI18nTest {

    private final GlobalExceptionHandler handler = newHandler();

    private static GlobalExceptionHandler newHandler() {
        ResourceBundleMessageSource ms = new ResourceBundleMessageSource();
        ms.setBasename("messages");
        ms.setDefaultEncoding("UTF-8");
        ms.setFallbackToSystemLocale(false);   // mirror application.properties: base bundle (vi) is the fallback
        return new GlobalExceptionHandler(new Messages(ms));
    }

    @AfterEach
    void reset() {
        LocaleContextHolder.resetLocaleContext();
    }

    @Test
    void codedAppException_isLocalizedToEnglish() {
        LocaleContextHolder.setLocale(Locale.ENGLISH);
        ResponseEntity<ApiResponse<Void>> r = handler.handleAppException(AppException.of("MSG11"));
        assertEquals(HttpStatus.BAD_REQUEST, r.getStatusCode());
        assertEquals("Insufficient points balance.", r.getBody().getMessage());
    }

    @Test
    void codedAppException_isLocalizedToVietnameseByDefault() {
        LocaleContextHolder.setLocale(Locale.forLanguageTag("vi"));
        ResponseEntity<ApiResponse<Void>> r = handler.handleAppException(AppException.of("MSG11"));
        assertEquals("Số dư điểm không đủ.", r.getBody().getMessage());
    }

    @Test
    void legacyLiteralMessage_passesThroughVerbatim() {
        ResponseEntity<ApiResponse<Void>> r = handler.handleAppException(new AppException("Lỗi nghiệp vụ tùy biến"));
        assertEquals("Lỗi nghiệp vụ tùy biến", r.getBody().getMessage());
    }

    @Test
    void genericException_doesNotLeakInternalDetail() {
        LocaleContextHolder.setLocale(Locale.ENGLISH);
        ResponseEntity<ApiResponse<Void>> r = handler.handleGenericException(new RuntimeException("stack secret"));
        assertEquals(HttpStatus.INTERNAL_SERVER_ERROR, r.getStatusCode());
        assertEquals("An unexpected error occurred.", r.getBody().getMessage());
    }
}
