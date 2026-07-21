package com.khoga.pos;

import com.khoga.common.exception.AppException;
import com.khoga.common.model.ShiftSession;
import com.khoga.common.model.Store;
import com.khoga.common.model.User;
import com.khoga.common.model.enums.OrderStatus;
import com.khoga.common.model.enums.PaymentMethod;
import com.khoga.common.model.enums.PaymentStatus;
import com.khoga.common.model.enums.RefundType;
import com.khoga.common.model.enums.Role;
import com.khoga.common.model.enums.ShiftStatus;
import com.khoga.common.repository.OrderRefundRepository;
import com.khoga.common.repository.OrderRepository;
import com.khoga.common.repository.ShiftSessionRepository;
import com.khoga.common.repository.UserRepository;
import com.khoga.integration.EmailService;
import com.khoga.pos.dto.OpenShiftRequest;
import com.khoga.pos.dto.ShiftResponse;
import com.khoga.pos.dto.ZReportResponse;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/** P2.2 unit tests for shift rules: one-open-per-register (BR-92), close blocked by orders (BR-03), discrepancy alert (BR-04). */
@ExtendWith(MockitoExtension.class)
class ShiftServiceTest {

    @Mock private ShiftSessionRepository shiftSessionRepository;
    @Mock private OrderRepository orderRepository;
    @Mock private OrderRefundRepository orderRefundRepository;
    @Mock private UserRepository userRepository;
    @Mock private EmailService emailService;
    @InjectMocks private ShiftService service;

    private final UUID userId = UUID.randomUUID();
    private final UUID storeId = UUID.randomUUID();

    private User actor() {
        Store store = new Store();
        store.setId(storeId);
        store.setName("Branch 1");
        User user = new User();
        user.setId(userId);
        user.setStore(store);
        return user;
    }

    private ShiftSession openSession(UUID id) {
        Store store = new Store();
        store.setId(storeId);
        store.setName("Branch 1");
        ShiftSession s = new ShiftSession();
        s.setId(id);
        s.setStore(store);
        s.setStatus(ShiftStatus.OPEN);
        s.setStartingCash(new BigDecimal("500000"));
        s.setPosRegisterId("REG-01");
        return s;
    }

    @Test
    void open_duplicateRegister_throws() {
        when(userRepository.findById(userId)).thenReturn(Optional.of(actor()));
        when(shiftSessionRepository.existsByStoreIdAndPosRegisterIdAndStatus(storeId, "REG-01", ShiftStatus.OPEN))
                .thenReturn(true);

        assertThrows(AppException.class, () -> service.openShift(
                new OpenShiftRequest("REG-01", BigDecimal.ZERO), userId));
        verify(shiftSessionRepository, never()).save(any());
    }

    @Test
    void open_createsOpenShift() {
        when(userRepository.findById(userId)).thenReturn(Optional.of(actor()));
        when(shiftSessionRepository.existsByStoreIdAndPosRegisterIdAndStatus(storeId, "REG-01", ShiftStatus.OPEN))
                .thenReturn(false);
        when(shiftSessionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        ShiftResponse res = service.openShift(new OpenShiftRequest("REG-01", new BigDecimal("500000")), userId);

        assertEquals(ShiftStatus.OPEN, res.status());
        assertEquals("REG-01", res.posRegisterId());
    }

    @Test
    void close_withNonTerminalOrders_blocks_BR03() {
        UUID sid = UUID.randomUUID();
        ShiftSession session = openSession(sid);
        when(userRepository.findById(userId)).thenReturn(Optional.of(actor()));
        when(shiftSessionRepository.findById(sid)).thenReturn(Optional.of(session));
        when(orderRepository.existsByShiftSessionIdAndStatusIn(eq(sid), anyCollection())).thenReturn(true);

        assertThrows(AppException.class, () -> service.closeShift(sid, new BigDecimal("500000"), null, userId));
        verify(shiftSessionRepository, never()).save(any());
    }

    @Test
    void close_discrepancyOverThreshold_flagsAndEmailsSM_BR04() {
        UUID sid = UUID.randomUUID();
        ShiftSession session = openSession(sid);
        User sm = new User();
        sm.setRole(Role.STORE_MANAGER);
        sm.setIsActive(true);
        sm.setEmail("sm@khoga.test");

        when(userRepository.findById(userId)).thenReturn(Optional.of(actor()));
        when(shiftSessionRepository.findById(sid)).thenReturn(Optional.of(session));
        when(orderRepository.existsByShiftSessionIdAndStatusIn(eq(sid), anyCollection())).thenReturn(false);
        when(orderRepository.sumSales(sid, PaymentMethod.CASH, PaymentStatus.PAID))
                .thenReturn(new BigDecimal("1000000"));
        when(orderRefundRepository.sumByShiftAndType(sid, RefundType.REFUND)).thenReturn(BigDecimal.ZERO);
        when(userRepository.findByStoreId(storeId)).thenReturn(List.of(sm));

        // expected = 500000 + 1000000 = 1500000; counted 1200000 → discrepancy -300000 (> 100k) → flagged
        ZReportResponse z = service.closeShift(sid, new BigDecimal("1200000"), null, userId);

        assertTrue(z.discrepancyFlagged());
        assertEquals(0, z.discrepancy().compareTo(new BigDecimal("-300000")));
        assertEquals(0, z.expectedCash().compareTo(new BigDecimal("1500000")));
        assertEquals(ShiftStatus.CLOSED, session.getStatus());
        verify(emailService).send(eq("sm@khoga.test"), any(), any());
    }
}
