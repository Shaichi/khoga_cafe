package com.khoga.report;

import com.khoga.common.model.User;
import com.khoga.common.model.enums.RefundType;
import com.khoga.common.repository.OrderCancellationRepository;
import com.khoga.common.repository.OrderRefundRepository;
import com.khoga.common.repository.OrderRepository;
import com.khoga.common.repository.UserRepository;
import com.khoga.config.SystemConfigService;
import com.khoga.report.dto.AnomalyReport;
import com.khoga.report.dto.CashierAnomalyRow;
import com.khoga.report.dto.CashierCount;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * UC-82 cashier void/refund anomaly detector (BR-79). Per cashier per period it tallies orders,
 * cancellations (BR-51), refunds + comps (BR-67) and voucher applications (BR-80), computes
 * cancel/refund rates, and flags any cashier exceeding the configurable
 * {@code CANCEL_REFUND_ALERT_THRESHOLD}. Detective control only — it blocks nothing.
 */
@Service
public class AnomalyDetector {

    private final OrderRepository orderRepository;
    private final OrderCancellationRepository orderCancellationRepository;
    private final OrderRefundRepository orderRefundRepository;
    private final UserRepository userRepository;
    private final SystemConfigService config;
    private final ReportScopeResolver scope;

    public AnomalyDetector(OrderRepository orderRepository,
                           OrderCancellationRepository orderCancellationRepository,
                           OrderRefundRepository orderRefundRepository,
                           UserRepository userRepository,
                           SystemConfigService config,
                           ReportScopeResolver scope) {
        this.orderRepository = orderRepository;
        this.orderCancellationRepository = orderCancellationRepository;
        this.orderRefundRepository = orderRefundRepository;
        this.userRepository = userRepository;
        this.config = config;
        this.scope = scope;
    }

    public AnomalyReport detect(LocalDate from, LocalDate to, UUID branchFilter, UUID actorId) {
        UUID branch = scope.resolveBranch(actorId, branchFilter); // null = chain (HQ)
        LocalDateTime fromDt = from.atStartOfDay();
        LocalDateTime toDt = to.plusDays(1).atStartOfDay();
        BigDecimal threshold = config.getGlobalDecimal("CANCEL_REFUND_ALERT_THRESHOLD", new BigDecimal("5"));

        Map<UUID, Long> orders = toMap(orderRepository.ordersByCashier(branch, fromDt, toDt));
        Map<UUID, Long> cancels = toMap(orderCancellationRepository.countByCashier(branch, fromDt, toDt));
        Map<UUID, Long> refunds = toMap(orderRefundRepository.countByCashier(branch, RefundType.REFUND, fromDt, toDt));
        Map<UUID, Long> comps = toMap(orderRefundRepository.countByCashier(branch, RefundType.COMP_REMAKE, fromDt, toDt));
        Map<UUID, Long> vouchers = toMap(orderRepository.vouchersByCashier(branch, fromDt, toDt));

        Set<UUID> cashierIds = new LinkedHashSet<>();
        cashierIds.addAll(orders.keySet());
        cashierIds.addAll(cancels.keySet());
        cashierIds.addAll(refunds.keySet());
        cashierIds.addAll(comps.keySet());
        cashierIds.addAll(vouchers.keySet());

        Map<UUID, String> names = userRepository.findAllById(cashierIds).stream()
                .collect(Collectors.toMap(User::getId, u -> u.getFullName() != null ? u.getFullName() : u.getUsername()));

        List<CashierAnomalyRow> rows = cashierIds.stream()
                .map(id -> row(id, names.getOrDefault(id, "—"), orders, cancels, refunds, comps, vouchers, threshold))
                .toList();

        return new AnomalyReport(from, to, branch, threshold, rows);
    }

    private CashierAnomalyRow row(UUID id, String name, Map<UUID, Long> orders, Map<UUID, Long> cancels,
                                  Map<UUID, Long> refunds, Map<UUID, Long> comps, Map<UUID, Long> vouchers,
                                  BigDecimal threshold) {
        long o = orders.getOrDefault(id, 0L);
        long c = cancels.getOrDefault(id, 0L);
        long r = refunds.getOrDefault(id, 0L);
        BigDecimal cancelRate = rate(c, o);
        BigDecimal refundRate = rate(r, o);
        boolean flagged = cancelRate.compareTo(threshold) > 0 || refundRate.compareTo(threshold) > 0;
        return new CashierAnomalyRow(id, name, o, c, cancelRate, r, refundRate,
                vouchers.getOrDefault(id, 0L), comps.getOrDefault(id, 0L), flagged);
    }

    private static BigDecimal rate(long count, long orders) {
        if (orders == 0) {
            return BigDecimal.ZERO;
        }
        return BigDecimal.valueOf(count).multiply(BigDecimal.valueOf(100))
                .divide(BigDecimal.valueOf(orders), 2, RoundingMode.HALF_UP);
    }

    private static Map<UUID, Long> toMap(List<CashierCount> counts) {
        Map<UUID, Long> map = new HashMap<>();
        for (CashierCount cc : counts) {
            if (cc.cashierId() != null) {
                map.put(cc.cashierId(), cc.count());
            }
        }
        return map;
    }
}
