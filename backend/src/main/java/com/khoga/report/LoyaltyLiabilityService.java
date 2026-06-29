package com.khoga.report;

import com.khoga.common.model.AuditLog;
import com.khoga.common.repository.AuditLogRepository;
import com.khoga.common.repository.CustomerRepository;
import com.khoga.common.repository.OrderRepository;
import com.khoga.customer.LoyaltyExpiryService;
import com.khoga.report.dto.LoyaltyLiabilityReport;
import com.khoga.report.dto.LoyaltyMovement;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.UUID;

/**
 * UC-78 loyalty liability & movement (BR-75). Outstanding balance = sum of all active customers'
 * current points (chain-wide, points only). The movement reconciles
 * {@code opening + issued − redeemed − expired = closing} for the period, with closing pinned to the
 * current outstanding balance and opening derived from it.
 *
 * <p>{@code expired} is sourced (chain-wide) from the {@code "LoyaltyExpiry"} audit rows written by
 * {@link LoyaltyExpiryService} (BR-35), so the movement now reconciles to the real expiries.
 */
@Service
public class LoyaltyLiabilityService {

    private static final Pattern POINTS = Pattern.compile("\"points\"\\s*:\\s*(\\d+)");
    private static final String NOTE =
            "Điểm hết hạn (BR-35) lấy từ nhật ký hết hạn toàn chuỗi; số dư đầu kỳ suy ra từ đối soát.";

    private final CustomerRepository customerRepository;
    private final OrderRepository orderRepository;
    private final AuditLogRepository auditLogRepository;
    private final ReportScopeResolver scope;

    public LoyaltyLiabilityService(CustomerRepository customerRepository,
                                   OrderRepository orderRepository,
                                   AuditLogRepository auditLogRepository,
                                   ReportScopeResolver scope) {
        this.customerRepository = customerRepository;
        this.orderRepository = orderRepository;
        this.auditLogRepository = auditLogRepository;
        this.scope = scope;
    }

    public LoyaltyLiabilityReport liability(LocalDate from, LocalDate to, UUID branchFilter, UUID actorId) {
        UUID branch = scope.resolveBranch(actorId, branchFilter); // movement scope; outstanding stays chain-wide
        LocalDateTime fromDt = from.atStartOfDay();
        LocalDateTime toDt = to.plusDays(1).atStartOfDay();

        long closing = customerRepository.sumOutstandingPoints();
        long issued = orderRepository.sumPointsEarned(branch, fromDt, toDt);
        long redeemed = orderRepository.sumPointsRedeemed(branch, fromDt, toDt);
        long expired = expiredInWindow(fromDt, toDt); // chain-wide (points are not branch-scoped)
        long opening = closing - issued + redeemed + expired;

        LoyaltyMovement movement = new LoyaltyMovement(opening, issued, redeemed, expired, closing);
        return new LoyaltyLiabilityReport(from, to, branch, closing, movement, NOTE);
    }

    /** Sums the points expired (BR-35) in the window from the immutable expiry audit trail. */
    private long expiredInWindow(LocalDateTime from, LocalDateTime to) {
        long total = 0;
        for (AuditLog a : auditLogRepository.findByEntityAffectedAndCreatedAtBetween(
                LoyaltyExpiryService.AUDIT_ENTITY, from, to)) {
            Matcher m = POINTS.matcher(a.getNewValueJson() == null ? "" : a.getNewValueJson());
            if (m.find()) {
                total += Long.parseLong(m.group(1));
            }
        }
        return total;
    }
}
