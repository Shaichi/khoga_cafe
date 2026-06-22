package com.khoga.common.repository;

import com.khoga.common.model.User;
import com.khoga.common.model.enums.Role;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserRepository extends JpaRepository<User, UUID> {

    Optional<User> findByUsername(String username);

    Optional<User> findByEmail(String email);

    boolean existsByUsername(String username);

    List<User> findByStoreId(UUID storeId);

    long countByRoleAndIsActiveTrue(Role role);
}
