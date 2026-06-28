package com.khoga.common.repository;

import com.khoga.common.model.SystemConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface SystemConfigRepository extends JpaRepository<SystemConfig, UUID> {

    Optional<SystemConfig> findFirstByConfigKeyAndScope(String configKey, String scope);

    Optional<SystemConfig> findFirstByConfigKeyAndScopeAndStoreId(String configKey, String scope, UUID storeId);

    /** All configs in a scope, ordered by key — used by the central settings screen (UC-24). */
    List<SystemConfig> findByScopeOrderByConfigKey(String scope);
}
