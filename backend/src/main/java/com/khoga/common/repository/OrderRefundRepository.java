package com.khoga.common.repository;

import com.khoga.common.model.OrderRefund;
import com.khoga.common.model.enums.RefundType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.UUID;

@Repository
public interface OrderRefundRepository extends JpaRepository<OrderRefund, UUID> {

    /** Sum of cash refunds attached to a shift (BR-09) — reduces the expected drawer at close. */
    @Query("select coalesce(sum(r.amount), 0) from OrderRefund r "
            + "where r.shiftSession.id = :sessionId and r.refundType = :type")
    BigDecimal sumByShiftAndType(@Param("sessionId") UUID sessionId, @Param("type") RefundType type);
}
