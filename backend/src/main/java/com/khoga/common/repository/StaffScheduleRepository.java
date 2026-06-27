package com.khoga.common.repository;

import com.khoga.common.model.StaffSchedule;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Repository
public interface StaffScheduleRepository extends JpaRepository<StaffSchedule, UUID> {

    /** BR-56: when a branch is deactivated, future schedules are removed (history is kept). */
    long deleteByStoreIdAndShiftDateGreaterThanEqual(UUID storeId, LocalDate date);

    /** UC-35 — branch schedule calendar over a date window. */
    List<StaffSchedule> findByStoreIdAndShiftDateBetween(UUID storeId, LocalDate from, LocalDate to);

    /** UC-39/80 — schedules for one branch + day. */
    List<StaffSchedule> findByStoreIdAndShiftDate(UUID storeId, LocalDate shiftDate);

    /** BR-92 daily-hours + conflict check for one employee on a day. */
    List<StaffSchedule> findByUserIdAndShiftDate(UUID userId, LocalDate shiftDate);

    /** BR-92 weekly-hours + min-rest window for one employee. */
    List<StaffSchedule> findByUserIdAndShiftDateBetween(UUID userId, LocalDate from, LocalDate to);
}
