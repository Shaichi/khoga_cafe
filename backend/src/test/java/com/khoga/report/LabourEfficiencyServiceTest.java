package com.khoga.report;

import com.khoga.common.model.AttendanceLog;
import com.khoga.common.model.Store;
import com.khoga.common.repository.AttendanceLogRepository;
import com.khoga.common.repository.OrderRepository;
import com.khoga.report.dto.BranchRevenueRow;
import com.khoga.report.dto.LabourReport;
import com.khoga.report.dto.LabourRow;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.when;

/** UC-79: worked-hours vs net-sales ratios per branch + chain total. */
@ExtendWith(MockitoExtension.class)
class LabourEfficiencyServiceTest {

    @Mock private AttendanceLogRepository attendanceLogRepository;
    @Mock private OrderRepository orderRepository;
    @Mock private ReportScopeResolver scope;
    @InjectMocks private LabourEfficiencyService service;

    private final UUID actor = UUID.randomUUID();
    private final UUID storeA = UUID.randomUUID();
    private final LocalDate from = LocalDate.of(2026, 5, 1);
    private final LocalDate to = LocalDate.of(2026, 5, 31);

    private AttendanceLog pairing(UUID storeId, String name, LocalDateTime in, LocalDateTime out) {
        Store s = new Store();
        s.setId(storeId);
        s.setName(name);
        AttendanceLog log = new AttendanceLog();
        log.setStore(s);
        log.setCheckInAt(in);
        log.setCheckOutAt(out);
        return log;
    }

    @Test
    void labour_computesHoursAndRatiosWithChainTotal() {
        when(scope.resolveBranch(actor, null)).thenReturn(null);
        // 10 worked hours at branch A (08:00 → 18:00).
        when(attendanceLogRepository.findByShiftDateBetween(from, to)).thenReturn(List.of(
                pairing(storeA, "District 1",
                        LocalDateTime.of(2026, 5, 2, 8, 0), LocalDateTime.of(2026, 5, 2, 18, 0))));
        when(orderRepository.netSalesByBranch(isNull(), any(), any())).thenReturn(List.of(
                new BranchRevenueRow(storeA, "District 1", new BigDecimal("5000000"), 100)));

        LabourReport r = service.labour(from, to, null, actor);

        LabourRow row = r.branches().get(0);
        assertEquals(new BigDecimal("10.00"), row.labourHours());
        assertEquals(new BigDecimal("5000000"), row.netSales());
        // hours per 1M = 10 / (5,000,000 / 1,000,000) = 10 / 5 = 2.00
        assertEquals(new BigDecimal("2.00"), row.hoursPerMillion());
        // VND per hour = 5,000,000 / 10 = 500,000
        assertEquals(new BigDecimal("500000"), row.vndPerHour());
        assertNotNull(r.chainTotal());
        assertEquals(new BigDecimal("10.00"), r.chainTotal().labourHours());
    }

    @Test
    void labour_storeManagerScopeHasNoChainTotal() {
        when(scope.resolveBranch(actor, null)).thenReturn(storeA);
        when(attendanceLogRepository.findByStoreIdAndShiftDateBetween(storeA, from, to)).thenReturn(List.of());
        when(orderRepository.netSalesByBranch(any(), any(), any())).thenReturn(List.of());

        LabourReport r = service.labour(from, to, null, actor);

        org.junit.jupiter.api.Assertions.assertNull(r.chainTotal());
    }
}
