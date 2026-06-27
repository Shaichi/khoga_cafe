package com.khoga.common.repository;

import com.khoga.common.model.AttendanceLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface AttendanceLogRepository extends JpaRepository<AttendanceLog, UUID> {

    /** UC-39/80 — attendance logs for one branch over a date window. */
    List<AttendanceLog> findByStoreIdAndShiftDateBetween(UUID storeId, LocalDate from, LocalDate to);

    /** UC-67 check-out — the open (not yet checked-out) pairing for an employee on a day. */
    Optional<AttendanceLog> findFirstByUserIdAndShiftDateAndCheckOutAtIsNull(UUID userId, LocalDate shiftDate);

    /** Guard against a second open check-in for the same employee on the same day. */
    boolean existsByUserIdAndShiftDateAndCheckOutAtIsNull(UUID userId, LocalDate shiftDate);

    /** SM verification queue (BR-93 fallback): photoless check-ins awaiting confirmation. */
    List<AttendanceLog> findByStoreIdAndPendingVerificationTrue(UUID storeId);

    /** BR-72 (PDPA) — photos older than the retention window, still present. */
    List<AttendanceLog> findByPhotoUrlIsNotNullAndCheckInAtBefore(LocalDateTime cutoff);
}
