package com.khoga.staff.dto;

import jakarta.validation.constraints.NotBlank;

/** UC-67 check-out: same PIN re-identifies the employee; updates the open pairing's checkOutAt. */
public record CheckOutRequest(
        @NotBlank String pin) {
}
