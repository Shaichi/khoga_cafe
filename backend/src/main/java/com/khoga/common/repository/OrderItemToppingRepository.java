package com.khoga.common.repository;

import com.khoga.common.model.OrderItemTopping;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.UUID;

@Repository
public interface OrderItemToppingRepository extends JpaRepository<OrderItemTopping, UUID> {

    List<OrderItemTopping> findByOrderItemId(UUID orderItemId);
}
