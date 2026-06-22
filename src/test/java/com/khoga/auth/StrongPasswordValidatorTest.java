package com.khoga.auth;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * P0.8 unit tests for the BR-14 password policy. The validator does not use the context, so passing
 * {@code null} for it is safe.
 */
class StrongPasswordValidatorTest {

    private final StrongPasswordValidator validator = new StrongPasswordValidator();

    @Test
    void rejectsNull() {
        assertFalse(validator.isValid(null, null));
    }

    @Test
    void rejectsTooShort() {
        assertFalse(validator.isValid("Aa1!", null));
    }

    @Test
    void rejectsMissingUppercase() {
        assertFalse(validator.isValid("secret@123", null));
    }

    @Test
    void rejectsMissingLowercase() {
        assertFalse(validator.isValid("SECRET@123", null));
    }

    @Test
    void rejectsMissingDigit() {
        assertFalse(validator.isValid("Secret@abc", null));
    }

    @Test
    void rejectsMissingSpecialCharacter() {
        assertFalse(validator.isValid("Secret1234", null));
    }

    @Test
    void acceptsStrongPassword() {
        assertTrue(validator.isValid("Secret@123", null));
    }
}
