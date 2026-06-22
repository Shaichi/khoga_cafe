package com.khoga.customer.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

/**
 * PDPA consent is mandatory before storing contact data (BR-71): {@code consentVersion} must be
 * supplied; the server stamps {@code consentAt}.
 */
public record CreateCustomerRequest(
        @NotBlank @Pattern(regexp = "^[0-9]{10,12}$", message = "Số điện thoại phải có 10–12 chữ số") String phone,
        @NotBlank(message = "Tên khách hàng không được để trống") String fullName,
        @Email(message = "Email không hợp lệ") String email,
        java.time.LocalDate birthDate,
        @NotBlank(message = "Phải có phiên bản đồng ý (consent) trước khi lưu thông tin") String consentVersion) {
}
