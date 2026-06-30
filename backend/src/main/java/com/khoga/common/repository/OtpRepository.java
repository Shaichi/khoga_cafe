package com.khoga.common.repository;

import com.khoga.common.model.OtpEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;

@Repository
public interface OtpRepository extends JpaRepository<OtpEntity, String> {

    @Modifying
    @Query("DELETE FROM OtpEntity o WHERE o.expiresAt < :now")
    int deleteExpired(LocalDateTime now);
}
