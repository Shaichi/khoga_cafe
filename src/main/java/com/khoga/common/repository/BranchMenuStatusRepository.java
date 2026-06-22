package com.khoga.common.repository;

import com.khoga.common.model.BranchMenuStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface BranchMenuStatusRepository extends JpaRepository<BranchMenuStatus, UUID> {

    Optional<BranchMenuStatus> findFirstByStoreIdAndMenuItemId(UUID storeId, UUID menuItemId);
}
