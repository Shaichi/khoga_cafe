package com.khoga.common.repository;

import com.khoga.common.model.ShiftSession;
import com.khoga.common.model.enums.ShiftStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ShiftSessionRepository extends JpaRepository<ShiftSession, UUID> {

    boolean existsByStoreIdAndStatus(UUID storeId, ShiftStatus status);

    boolean existsByStoreIdAndPosRegisterIdAndStatus(UUID storeId, String posRegisterId, ShiftStatus status);

    Optional<ShiftSession> findFirstByUserIdAndStatus(UUID userId, ShiftStatus status);

    /** Any open shift at a branch — used to attach a cash refund's drawer impact (BR-09). */
    Optional<ShiftSession> findFirstByStoreIdAndStatus(UUID storeId, ShiftStatus status);

    List<ShiftSession> findByStatus(ShiftStatus status);

    /** UC-40/81 — shifts at a branch that started within a window (Z-report day, discrepancy totals). */
    List<ShiftSession> findByStoreIdAndStartTimeBetween(UUID storeId, LocalDateTime from, LocalDateTime to);
}
