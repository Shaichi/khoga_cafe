package com.khoga.report;

import com.khoga.common.repository.CustomerRepository;
import com.khoga.common.repository.OrderRepository;
import com.khoga.report.dto.LoyaltyLiabilityReport;
import com.khoga.report.dto.LoyaltyMovement;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * UC-78 loyalty liability & movement (BR-75). Outstanding balance = sum of all active customers'
 * current points (chain-wide, points only). The movement reconciles
 * {@code opening + issued − redeemed − expired = closing} for the period, with closing pinned to the
 * current outstanding balance and opening derived from it.
 *
 * <p>Expiry (BR-35, 12-month inactivity) is not yet enforced — that job lands in P4 — so
 * {@code expired} is reported as 0 with an explanatory note rather than a fabricated figure.
 */
@Service
public class LoyaltyLiabilityService {

    private static final String EXPIRY_NOTE =
            "Hết hạn điểm (BR-35) chưa kích hoạt — sẽ bổ sung ở P4; tạm tính = 0.";

    private final CustomerRepository customerRepository;
    private final OrderRepository orderRepository;
    private final ReportScopeResolver scope;

    public LoyaltyLiabilityService(CustomerRepository customerRepository,
                                   OrderRepository orderRepository,
                                   ReportScopeResolver scope) {
        this.customerRepository = customerRepository;
        this.orderRepository = orderRepository;
        this.scope = scope;
    }

    public LoyaltyLiabilityReport liability(LocalDate from, LocalDate to, UUID branchFilter, UUID actorId) {
        UUID branch = scope.resolveBranch(actorId, branchFilter); // movement scope; outstanding stays chain-wide
        LocalDateTime fromDt = from.atStartOfDay();
        LocalDateTime toDt = to.plusDays(1).atStartOfDay();

        long closing = customerRepository.sumOutstandingPoints();
        long issued = orderRepository.sumPointsEarned(branch, fromDt, toDt);
        long redeemed = orderRepository.sumPointsRedeemed(branch, fromDt, toDt);
        long expired = 0L; // BR-35 deferred to P4
        long opening = closing - issued + redeemed + expired;

        LoyaltyMovement movement = new LoyaltyMovement(opening, issued, redeemed, expired, closing);
        return new LoyaltyLiabilityReport(from, to, branch, closing, movement, EXPIRY_NOTE);
    }
}
