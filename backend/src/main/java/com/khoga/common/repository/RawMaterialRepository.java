package com.khoga.common.repository;

import com.khoga.common.model.RawMaterial;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface RawMaterialRepository extends JpaRepository<RawMaterial, UUID> {

    boolean existsByCodeIgnoreCase(String code);

    Page<RawMaterial> findByIsActive(Boolean isActive, Pageable pageable);

    Page<RawMaterial> findByCodeContainingIgnoreCaseOrNameContainingIgnoreCase(
            String code, String name, Pageable pageable);
}
