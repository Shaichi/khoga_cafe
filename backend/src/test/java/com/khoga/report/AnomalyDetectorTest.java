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
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.when;

/** UC-82: per-cashier cancel/refund rates flagged above CANCEL_REFUND_ALERT_THRESHOLD (BR-79). */
@ExtendWith(MockitoExtension.class)
class AnomalyDetectorTest {

    @Mock private OrderRepository orderRepository;
    @Mock private OrderCancellationRepository orderCancellationRepository;
    @Mock private OrderRefundRepository orderRefundRepository;
    @Mock private UserRepository userRepository;
    @Mock private SystemConfigService config;
    @Mock private ReportScopeResolver scope;
    @InjectMocks private AnomalyDetector detector;

    private final UUID actor = UUID.randomUUID();
    private final UUID storeA = UUID.randomUUID();
    private final UUID an = UUID.randomUUID();   // 8/612 = 1.3% — clean
    private final UUID binh = UUID.randomUUID();  // 39/470 = 8.3% — flagged
    private final LocalDate from = LocalDate.of(2026, 5, 1);
    private final LocalDate to = LocalDate.of(2026, 5, 31);

    private User user(UUID id, String name) {
        User u = new User();
        u.setId(id);
        u.setFullName(name);
        return u;
    }

    @Test
    void flagsCashiersAboveThreshold() {
        when(scope.resolveBranch(actor, storeA)).thenReturn(storeA);
        when(config.getGlobalDecimal(eq("CANCEL_REFUND_ALERT_THRESHOLD"), any())).thenReturn(new BigDecimal("5"));
        when(orderRepository.ordersByCashier(eq(storeA), any(), any()))
                .thenReturn(List.of(new CashierCount(an, 612), new CashierCount(binh, 470)));
        when(orderCancellationRepository.countByCashier(eq(storeA), any(), any()))
                .thenReturn(List.of(new CashierCount(an, 8), new CashierCount(binh, 39)));
        when(orderRefundRepository.countByCashier(eq(storeA), eq(RefundType.REFUND), any(), any()))
                .thenReturn(List.of(new CashierCount(an, 3), new CashierCount(binh, 17)));
        when(orderRefundRepository.countByCashier(eq(storeA), eq(RefundType.COMP_REMAKE), any(), any()))
                .thenReturn(List.of(new CashierCount(binh, 9)));
        when(orderRepository.vouchersByCashier(eq(storeA), any(), any()))
                .thenReturn(List.of(new CashierCount(an, 41), new CashierCount(binh, 88)));
        when(userRepository.findAllById(any())).thenReturn(List.of(user(an, "An"), user(binh, "Binh")));

        AnomalyReport report = detector.detect(from, to, storeA, actor);

        CashierAnomalyRow anRow = report.cashiers().stream().filter(c -> c.cashierId().equals(an)).findFirst().orElseThrow();
        CashierAnomalyRow binhRow = report.cashiers().stream().filter(c -> c.cashierId().equals(binh)).findFirst().orElseThrow();

        assertEquals(new BigDecimal("1.31"), anRow.cancelRate()); // 8/612
        assertFalse(anRow.flagged());
        assertEquals(new BigDecimal("8.30"), binhRow.cancelRate()); // 39/470
        assertEquals(9, binhRow.comps());
        assertTrue(binhRow.flagged(), "8.3% cancel rate exceeds 5% threshold");
    }

    @Test
    void chainScopePassesNullBranch() {
        when(scope.resolveBranch(actor, null)).thenReturn(null);
        when(config.getGlobalDecimal(eq("CANCEL_REFUND_ALERT_THRESHOLD"), any())).thenReturn(new BigDecimal("5"));
        when(orderRepository.ordersByCashier(isNull(), any(), any())).thenReturn(List.of());
        when(orderCancellationRepository.countByCashier(isNull(), any(), any())).thenReturn(List.of());
        when(orderRefundRepository.countByCashier(isNull(), eq(RefundType.REFUND), any(), any())).thenReturn(List.of());
        when(orderRefundRepository.countByCashier(isNull(), eq(RefundType.COMP_REMAKE), any(), any())).thenReturn(List.of());
        when(orderRepository.vouchersByCashier(isNull(), any(), any())).thenReturn(List.of());
        when(userRepository.findAllById(any())).thenReturn(List.of());

        AnomalyReport report = detector.detect(from, to, null, actor);

        assertTrue(report.cashiers().isEmpty());
    }
}
