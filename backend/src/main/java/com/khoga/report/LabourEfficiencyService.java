package com.khoga.report;

import com.khoga.common.model.AttendanceLog;
import com.khoga.common.repository.AttendanceLogRepository;
import com.khoga.common.repository.OrderRepository;
import com.khoga.report.dto.BranchRevenueRow;
import com.khoga.report.dto.LabourReport;
import com.khoga.report.dto.LabourRow;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * UC-79 labour-hours vs revenue (BR-76/BR-77). Worked hours come from attendance pairings (check-in →
 * check-out); net sales from COMPLETED orders. Two ratios per branch: hours per 1,000,000 VND and
 * VND per labour hour. Deliberately non-monetary on the labour side — no wages (§1.2).
 */
@Service
public class LabourEfficiencyService {

    private static final BigDecimal MILLION = new BigDecimal("1000000");

    private final AttendanceLogRepository attendanceLogRepository;
    private final OrderRepository orderRepository;
    private final ReportScopeResolver scope;

    public LabourEfficiencyService(AttendanceLogRepository attendanceLogRepository,
                                   OrderRepository orderRepository,
                                   ReportScopeResolver scope) {
        this.attendanceLogRepository = attendanceLogRepository;
        this.orderRepository = orderRepository;
        this.scope = scope;
    }

    public LabourReport labour(LocalDate from, LocalDate to, UUID branchFilter, UUID actorId) {
        UUID branch = scope.resolveBranch(actorId, branchFilter); // null = chain (HQ)

        // Worked minutes per branch from attendance pairings.
        List<AttendanceLog> logs = branch == null
                ? attendanceLogRepository.findByShiftDateBetween(from, to)
                : attendanceLogRepository.findByStoreIdAndShiftDateBetween(branch, from, to);

        Map<UUID, Acc> byStore = new LinkedHashMap<>();
        for (AttendanceLog log : logs) {
            if (log.getStore() == null || log.getCheckInAt() == null || log.getCheckOutAt() == null) {
                continue;
            }
            UUID sid = log.getStore().getId();
            Acc acc = byStore.computeIfAbsent(sid, k -> new Acc(log.getStore().getName()));
            acc.minutes += Math.max(0, Duration.between(log.getCheckInAt(), log.getCheckOutAt()).toMinutes());
        }

        // Net sales per branch over the window.
        for (BranchRevenueRow r : orderRepository.netSalesByBranch(
                branch, from.atStartOfDay(), to.plusDays(1).atStartOfDay())) {
            Acc acc = byStore.computeIfAbsent(r.storeId(), k -> new Acc(r.storeName()));
            if (acc.storeName == null) {
                acc.storeName = r.storeName();
            }
            acc.netSales = acc.netSales.add(r.revenue());
        }

        List<LabourRow> rows = new ArrayList<>();
        long totalMinutes = 0;
        BigDecimal totalSales = BigDecimal.ZERO;
        for (Map.Entry<UUID, Acc> e : byStore.entrySet()) {
            Acc acc = e.getValue();
            rows.add(row(e.getKey(), acc.storeName, acc.minutes, acc.netSales));
            totalMinutes += acc.minutes;
            totalSales = totalSales.add(acc.netSales);
        }

        // Chain total only when consolidated (HQ, all branches).
        LabourRow chainTotal = branch == null ? row(null, "Toàn chuỗi", totalMinutes, totalSales) : null;

        return new LabourReport(from, to, branch, rows, chainTotal);
    }

    private LabourRow row(UUID storeId, String storeName, long minutes, BigDecimal netSales) {
        BigDecimal hours = BigDecimal.valueOf(minutes).divide(BigDecimal.valueOf(60), 2, RoundingMode.HALF_UP);
        BigDecimal hoursPerMillion = netSales.signum() == 0
                ? BigDecimal.ZERO
                : hours.divide(netSales.divide(MILLION, 6, RoundingMode.HALF_UP), 2, RoundingMode.HALF_UP);
        BigDecimal vndPerHour = hours.signum() == 0
                ? BigDecimal.ZERO
                : netSales.divide(hours, 0, RoundingMode.HALF_UP);
        return new LabourRow(storeId, storeName, hours, netSales, hoursPerMillion, vndPerHour);
    }

    /** Mutable per-branch accumulator. */
    private static final class Acc {
        private String storeName;
        private long minutes;
        private BigDecimal netSales = BigDecimal.ZERO;

        Acc(String storeName) {
            this.storeName = storeName;
        }
    }
}
