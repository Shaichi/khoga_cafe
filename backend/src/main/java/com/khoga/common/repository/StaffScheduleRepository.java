package com.khoga.common.repository;

import com.khoga.common.model.StaffSchedule;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.UUID;

@Repository
public interface StaffScheduleRepository extends JpaRepository<StaffSchedule, UUID> {

    /** BR-56: when a branch is deactivated, future schedules are removed (history is kept). */
    long deleteByStoreIdAndShiftDateGreaterThanEqual(UUID storeId, LocalDate date);
}
