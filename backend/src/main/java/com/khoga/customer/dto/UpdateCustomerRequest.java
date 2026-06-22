package com.khoga.customer.dto;

import jakarta.validation.constraints.Email;

/** UC-26: only name/email are editable here; point changes go through the adjustment endpoint. */
public record UpdateCustomerRequest(
        String fullName,
        @Email(message = "Email không hợp lệ") String email,
        java.time.LocalDate birthDate) {
}
