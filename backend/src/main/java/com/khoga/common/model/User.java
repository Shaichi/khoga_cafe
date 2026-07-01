package com.khoga.common.model;

import jakarta.persistence.*;
import lombok.*;
import java.util.UUID;
import java.time.LocalDateTime;
import java.math.BigDecimal;
import com.khoga.common.model.enums.*;

@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class User extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /** Sequential employee identifier, format {@code EMP-043} (BR-57). */
    private String employeeId;
    private String username;
    private String passwordHash;
    @Enumerated(EnumType.STRING)
    private Role role;
    private String fullName;
    private Boolean isActive;
    private String email;
    private String phone;
    @ManyToOne
    @JoinColumn(name = "store_id")
    private Store store;
    private LocalDateTime lastLoginAt;
    /** When the user last logged out (BR-13). Nullable; stamped by {@code AuthService.logout}. */
    private LocalDateTime lastLogoutAt;
    private Boolean mustChangePassword;
    private String attendancePin;
    private Integer failedAttempts;
    private LocalDateTime lockExpiryAt;
    private LocalDateTime passwordLastChangedAt;
    /**
     * BR-18 session-invalidation anchor. Bumped on every password change (and on deactivation);
     * the value is stamped into each issued JWT as the {@code tv} claim, so {@link
     * com.khoga.auth.JwtAuthenticationFilter} rejects any token whose {@code tv} no longer matches.
     * Nullable for legacy rows — a {@code null} is treated as {@code 0} everywhere it is compared.
     */
    private Integer tokenVersion;
    /** Attendance-PIN lockout (BR-93) — distinct from the login lockout above. */
    private Integer pinFailedAttempts;
    private LocalDateTime pinLockedUntil;
    private LocalDateTime lastActiveAt;
}
