package com.khoga.common.repository;

import com.khoga.common.model.Customer;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CustomerRepository extends JpaRepository<Customer, UUID> {

    boolean existsByPhone(String phone);

    Optional<Customer> findByPhone(String phone);

    Page<Customer> findByPhoneContainingOrFullNameContainingIgnoreCase(
            String phone, String fullName, Pageable pageable);

    /** UC-78 outstanding loyalty liability — total un-redeemed points across active customers (BR-75). */
    @Query("select coalesce(sum(c.points), 0) from Customer c where c.isActive = true")
    long sumOutstandingPoints();

    /**
     * BR-35 (P4) — active customers still holding points who have not transacted since {@code cutoff}
     * (and whose account predates it). Their points are due to expire (12-month inactivity).
     */
    @Query("select c from Customer c where c.points > 0 and c.isActive = true and c.createdAt < :cutoff "
            + "and not exists (select 1 from Order o where o.customer.id = c.id and o.createdAt >= :cutoff)")
    List<Customer> findPointsExpiryCandidates(@Param("cutoff") LocalDateTime cutoff);

    /**
     * BR-72 (P4, PDPA) — customers still holding PII who have not transacted since {@code cutoff}
     * (and whose account predates it). Their personal data is due to be anonymised (24-month inactivity).
     */
    @Query("select c from Customer c where (c.email is not null or c.phone is not null) and c.createdAt < :cutoff "
            + "and not exists (select 1 from Order o where o.customer.id = c.id and o.createdAt >= :cutoff)")
    List<Customer> findAnonymizationCandidates(@Param("cutoff") LocalDateTime cutoff);
}
