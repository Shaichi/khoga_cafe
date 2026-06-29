package com.khoga.common.i18n;

import org.junit.jupiter.api.Test;
import org.springframework.context.support.ResourceBundleMessageSource;

import java.util.Locale;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * P4 i18n — verifies the message bundles resolve per-locale, format arguments, and fall back to the
 * Vietnamese default for unsupported locales. Pure unit test against the real .properties files.
 */
class I18nMessageTest {

    private static ResourceBundleMessageSource bundle(String basename) {
        ResourceBundleMessageSource ms = new ResourceBundleMessageSource();
        ms.setBasename(basename);
        ms.setDefaultEncoding("UTF-8");
        ms.setFallbackToSystemLocale(false);   // mirror application.properties: base bundle (vi) is the fallback
        return ms;
    }

    private final ResourceBundleMessageSource messages = bundle("messages");

    @Test
    void resolvesVietnameseAsDefault() {
        assertEquals("Bạn không có quyền truy cập chức năng này.",
                messages.getMessage("MSG08", null, Locale.forLanguageTag("vi")));
    }

    @Test
    void resolvesEnglishWhenRequested() {
        assertEquals("Unauthorized action. You do not have permission to access this page.",
                messages.getMessage("MSG08", null, Locale.ENGLISH));
        assertEquals("Insufficient points balance.",
                messages.getMessage("MSG11", null, Locale.ENGLISH));
    }

    @Test
    void formatsArguments() {
        String vi = messages.getMessage("MSG16", new Object[]{3}, Locale.forLanguageTag("vi"));
        String en = messages.getMessage("MSG16", new Object[]{3}, Locale.ENGLISH);
        assertTrue(vi.contains("(3)"), vi);
        assertTrue(en.startsWith("Maximum branch capacity reached (3)"), en);
    }

    @Test
    void unsupportedLocaleFallsBackToVietnamese() {
        assertEquals(messages.getMessage("MSG03", null, Locale.forLanguageTag("vi")),
                messages.getMessage("MSG03", null, Locale.FRENCH));
    }

    @Test
    void validationBundleIsLocalized() {
        ResourceBundleMessageSource validation = bundle("ValidationMessages");
        assertTrue(validation.getMessage("khoga.password.strength", null, Locale.forLanguageTag("vi"))
                .contains("8 ký tự"));
        assertTrue(validation.getMessage("khoga.password.strength", null, Locale.ENGLISH)
                .contains("8 characters"));
    }
}
