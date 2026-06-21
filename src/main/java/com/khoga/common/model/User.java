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
    private Boolean mustChangePassword;
    private String attendancePin;
    private Integer failedAttempts;
    private LocalDateTime lockExpiryAt;
    private LocalDateTime passwordLastChangedAt;
}
