package com.khoga.common.model;

import jakarta.persistence.*;
import lombok.*;
import java.util.UUID;
import java.time.LocalDateTime;
import java.math.BigDecimal;
import com.khoga.common.model.enums.*;

@Entity
@Table(name = "staffschedules")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class StaffSchedule extends BaseEntity {

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
    @Enumerated(EnumType.STRING)
    private ShiftType shiftType;
    private java.time.LocalTime shiftStartTime;
    private java.time.LocalTime shiftEndTime;
    private String posRegisterId;
}
