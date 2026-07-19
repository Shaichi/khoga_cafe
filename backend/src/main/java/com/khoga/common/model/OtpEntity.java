package com.khoga.common.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@Entity
@Table(name = "otp_tokens")
public class OtpEntity {

    @Id
    @Column(name = "id", nullable = false, columnDefinition = "nvarchar(255)")
    private String id; // This will map to the "key" (e.g. email or username) used in OtpStore

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "code", nullable = false, length = 6, columnDefinition = "nvarchar(6)")
    private String code;

    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;

    @Column(name = "attempts", nullable = false)
    private int attempts = 0;
}
