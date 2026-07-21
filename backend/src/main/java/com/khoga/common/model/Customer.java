package com.khoga.common.model;

import jakarta.persistence.*;
import lombok.*;
import java.util.UUID;
import java.time.LocalDateTime;
import java.math.BigDecimal;
import com.khoga.common.model.enums.*;

@Entity
@Table(name = "customers")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Customer extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(columnDefinition = "nvarchar(255)")
    private String phone;
    @Column(columnDefinition = "nvarchar(255)")
    private String fullName;
    private Integer points;
    @Column(columnDefinition = "nvarchar(255)")
    private String email;
    private java.time.LocalDate birthDate;
    private Boolean isActive;
    private LocalDateTime consentAt;
    @Column(columnDefinition = "nvarchar(255)")
    private String consentVersion;
}
