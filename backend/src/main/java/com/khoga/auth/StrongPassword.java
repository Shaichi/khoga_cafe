package com.khoga.auth;

import jakarta.validation.Constraint;
import jakarta.validation.Payload;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Bean Validation constraint enforcing the password policy (BR-14): at least 8 characters with an
 * uppercase letter, a lowercase letter, a digit and a special character.
 */
@Documented
@Constraint(validatedBy = StrongPasswordValidator.class)
@Target({ElementType.FIELD, ElementType.PARAMETER, ElementType.RECORD_COMPONENT})
@Retention(RetentionPolicy.RUNTIME)
public @interface StrongPassword {

    // {key} is resolved by Hibernate Validator from ValidationMessages[_xx].properties (i18n, P4).
    String message() default "{khoga.password.strength}";

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};
}
