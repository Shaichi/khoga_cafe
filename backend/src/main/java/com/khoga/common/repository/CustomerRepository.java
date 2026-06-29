package com.khoga.common.repository;

import com.khoga.common.model.Customer;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

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
}
