package com.khoga.common.repository;

import com.khoga.common.model.Order;
import com.khoga.common.model.enums.OrderStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.UUID;

@Repository
public interface OrderRepository extends JpaRepository<Order, UUID> {

    boolean existsByStoreIdAndStatusIn(UUID storeId, Collection<OrderStatus> statuses);

    List<Order> findTop50ByCustomerIdOrderByCreatedAtDesc(UUID customerId);
}
