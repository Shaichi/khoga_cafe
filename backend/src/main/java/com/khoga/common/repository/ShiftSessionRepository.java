package com.khoga.common.repository;

import com.khoga.common.model.ShiftSession;
import com.khoga.common.model.enums.ShiftStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface ShiftSessionRepository extends JpaRepository<ShiftSession, UUID> {

    boolean existsByStoreIdAndStatus(UUID storeId, ShiftStatus status);
}
