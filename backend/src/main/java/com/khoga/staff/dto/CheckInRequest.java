package com.khoga.staff.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * UC-67 check-in: the branch-unique PIN identifies the employee (BR-93). {@code photoUrl} is the stored
 * snapshot; when blank the check-in is queued for Store Manager verification (BR-93 camera fallback).
 */
public record CheckInRequest(
        @NotBlank String pin,
        String photoUrl) {
}
