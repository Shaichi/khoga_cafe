package com.khoga.common.model;

import jakarta.persistence.*;
import lombok.*;
import java.util.UUID;
import java.time.LocalDateTime;
import java.math.BigDecimal;
import com.khoga.common.model.enums.*;

@Entity
@Table(name = "attendancelogs")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class AttendanceLog extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne
    @JoinColumn(name = "store_id")
    private Store store;
    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;
    private java.time.LocalDate shiftDate;
    private LocalDateTime checkInAt;
    private LocalDateTime checkOutAt;
    private LocalDateTime scheduledStart;
    @Enumerated(EnumType.STRING)
    private AttendanceStatus status;
    private String photoUrl;
    /** BR-93 fallback: check-in recorded without a photo, awaiting Store Manager verification. */
    private Boolean pendingVerification;
}
