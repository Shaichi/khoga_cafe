package com.khoga.staff.dto;

/** SM confirms a photoless check-in (BR-93 fallback); may attach the photo captured out-of-band. */
public record VerifyAttendanceRequest(
        String photoUrl) {
}
