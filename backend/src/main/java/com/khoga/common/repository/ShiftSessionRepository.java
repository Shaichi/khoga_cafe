package com.khoga.common.repository;

import com.khoga.common.model.ShiftSession;
import com.khoga.common.model.enums.ShiftStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ShiftSessionRepository extends JpaRepository<ShiftSession, UUID> {

    boolean existsByStoreIdAndStatus(UUID storeId, ShiftStatus status);

    boolean existsByStoreIdAndPosRegisterIdAndStatus(UUID storeId, String posRegisterId, ShiftStatus status);

    Optional<ShiftSession> findFirstByUserIdAndStatus(UUID userId, ShiftStatus status);

    List<ShiftSession> findByStatus(ShiftStatus status);
}
