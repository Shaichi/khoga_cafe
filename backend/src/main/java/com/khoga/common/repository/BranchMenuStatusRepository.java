package com.khoga.common.repository;

import com.khoga.common.model.BranchMenuStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface BranchMenuStatusRepository extends JpaRepository<BranchMenuStatus, UUID> {

    Optional<BranchMenuStatus> findFirstByStoreIdAndMenuItemId(UUID storeId, UUID menuItemId);

    /** UC-15: per-branch availability rows for a page of menu items at one store. */
    List<BranchMenuStatus> findByStoreIdAndMenuItemIdIn(UUID storeId, Collection<UUID> menuItemIds);
}
