package com.khoga.common.model;

import jakarta.persistence.*;
import lombok.*;
import java.util.UUID;
import java.time.LocalDateTime;
import java.math.BigDecimal;
import com.khoga.common.model.enums.*;

@Entity
@Table(name = "shiftsessions")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class ShiftSession extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne
    @JoinColumn(name = "store_id")
    private Store store;
    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private BigDecimal startingCash;
    private BigDecimal endingCash;
    @Enumerated(EnumType.STRING)
    private ShiftStatus status;
    private String posRegisterId;
    @Column(length = 1000)
    private String discrepancyNotes;
}
