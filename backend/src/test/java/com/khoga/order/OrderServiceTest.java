package com.khoga.order;

import com.khoga.audit.AuditLogService;
import com.khoga.common.exception.AppException;
import com.khoga.common.model.Customer;
import com.khoga.common.model.MenuItem;
import com.khoga.common.model.Order;
import com.khoga.common.model.OrderItem;
import com.khoga.common.model.ShiftSession;
import com.khoga.common.model.Store;
import com.khoga.common.model.User;
import com.khoga.common.model.Voucher;
import com.khoga.common.model.enums.OrderStatus;
import com.khoga.common.model.enums.PaymentMethod;
import com.khoga.common.model.enums.PaymentStatus;
import com.khoga.common.model.enums.RefundType;
import com.khoga.common.model.enums.Role;
import com.khoga.common.model.enums.ShiftStatus;
import com.khoga.common.repository.CustomerRepository;
import com.khoga.common.repository.OrderCancellationRepository;
import com.khoga.common.repository.OrderItemRepository;
import com.khoga.common.repository.OrderItemToppingRepository;
import com.khoga.common.repository.OrderRefundRepository;
import com.khoga.common.repository.OrderRepository;
import com.khoga.common.repository.ShiftSessionRepository;
import com.khoga.common.repository.UserRepository;
import com.khoga.common.repository.VoucherRepository;
import com.khoga.config.SystemConfigService;
import com.khoga.integration.PrinterService;
import com.khoga.inventory.RecipeDeductionEngine;
import com.khoga.inventory.dto.DeductionResult;
import com.khoga.order.dto.CancelOrderRequest;
import com.khoga.order.dto.RefundRequest;
import com.khoga.order.dto.RefundResponse;
import com.khoga.order.dto.StatusUpdateResponse;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * P2.3 unit tests for the order lifecycle: state-machine transitions + stock deduction (UC-58/62),
 * cancel guard + rollback (UC-55/BR-05/BR-08), SM refund/comp (UC-75/BR-09), auto-abandon (BR-88).
 */
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock private OrderRepository orderRepository;
    @Mock private OrderItemRepository orderItemRepository;
    @Mock private OrderItemToppingRepository orderItemToppingRepository;
    @Mock private OrderCancellationRepository orderCancellationRepository;
    @Mock private OrderRefundRepository orderRefundRepository;
    @Mock private ShiftSessionRepository shiftSessionRepository;
    @Mock private UserRepository userRepository;
    @Mock private CustomerRepository customerRepository;
    @Mock private VoucherRepository voucherRepository;
    @Mock private RecipeDeductionEngine recipeDeductionEngine;
    @Mock private SystemConfigService config;
    @Mock private PrinterService printerService;
    @Mock private AuditLogService auditLogService;
    @InjectMocks private OrderService service;

    private final UUID actorId = UUID.randomUUID();
    private final UUID storeId = UUID.randomUUID();
    private final UUID orderId = UUID.randomUUID();

    private Store store() {
        Store s = new Store();
        s.setId(storeId);
        s.setName("Branch 1");
        return s;
    }

    private User actor() {
        User u = new User();
        u.setId(actorId);
        u.setStore(store());
        return u;
    }

    private Order order(OrderStatus status, PaymentStatus payment) {
        Order o = new Order();
        o.setId(orderId);
        o.setStore(store());
        o.setOrderNumber("OD-1");
        o.setStatus(status);
        o.setPaymentStatus(payment);
        return o;
    }

    private User sm(String pin) {
        User u = new User();
        u.setId(UUID.randomUUID());
        u.setRole(Role.STORE_MANAGER);
        u.setIsActive(true);
        u.setAttendancePin(pin);
        u.setStore(store());
        return u;
    }

    // ---- UC-58 state machine ------------------------------------------------

    @Test
    void updateStatus_pendingToPreparing_deductsStock() {
        Order order = order(OrderStatus.PENDING, PaymentStatus.PAID);
        when(userRepository.findById(actorId)).thenReturn(Optional.of(actor()));
        when(orderRepository.findById(orderId)).thenReturn(Optional.of(order));
        when(recipeDeductionEngine.deductForOrder(order)).thenReturn(new DeductionResult(List.of()));

        StatusUpdateResponse res = service.updateStatus(orderId, OrderStatus.PREPARING, actorId);

        assertEquals(OrderStatus.PREPARING, res.status());
        assertTrue(res.stockWarnings().isEmpty());
        verify(recipeDeductionEngine).deductForOrder(order);
    }

    @Test
    void updateStatus_invalidTransition_throws() {
        Order order = order(OrderStatus.PENDING, PaymentStatus.PAID);
        when(userRepository.findById(actorId)).thenReturn(Optional.of(actor()));
        when(orderRepository.findById(orderId)).thenReturn(Optional.of(order));

        assertThrows(AppException.class, () -> service.updateStatus(orderId, OrderStatus.READY, actorId));
        verify(recipeDeductionEngine, never()).deductForOrder(any());
        verify(orderRepository, never()).save(any());
    }

    @Test
    void updateStatus_preparingToReady_printsLabel_noRededuct() {
        Order order = order(OrderStatus.PREPARING, PaymentStatus.PAID);
        when(userRepository.findById(actorId)).thenReturn(Optional.of(actor()));
        when(orderRepository.findById(orderId)).thenReturn(Optional.of(order));

        StatusUpdateResponse res = service.updateStatus(orderId, OrderStatus.READY, actorId);

        assertEquals(OrderStatus.READY, res.status());
        verify(printerService).printLabel(any());
        verify(recipeDeductionEngine, never()).deductForOrder(any());
    }

    // ---- UC-55 cancel -------------------------------------------------------

    @Test
    void cancel_nonPending_throws_BR05() {
        Order order = order(OrderStatus.PREPARING, PaymentStatus.PAID);
        when(userRepository.findById(actorId)).thenReturn(Optional.of(actor()));
        when(orderRepository.findById(orderId)).thenReturn(Optional.of(order));

        assertThrows(AppException.class,
                () -> service.cancelOrder(orderId, new CancelOrderRequest("đổi ý", null), actorId));
        verify(orderCancellationRepository, never()).save(any());
    }

    @Test
    void cancel_paidPending_rollbacksPointsAndVoucher_BR08() {
        // BR-08: cancelling a prepaid PENDING order reverses loyalty + voucher usage and marks it REFUNDED.
        Order order = order(OrderStatus.PENDING, PaymentStatus.PAID);
        Customer customer = new Customer();
        customer.setId(UUID.randomUUID());
        customer.setPoints(5);
        Voucher voucher = new Voucher();
        voucher.setId(UUID.randomUUID());
        voucher.setTotalUsageCount(3);
        order.setCustomer(customer);
        order.setVoucher(voucher);
        order.setPointsRedeemed(0);
        order.setPointsEarned(5);

        when(userRepository.findById(actorId)).thenReturn(Optional.of(actor()));
        when(orderRepository.findById(orderId)).thenReturn(Optional.of(order));
        when(orderItemRepository.countByOrderId(orderId)).thenReturn(2L);
        when(customerRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(voucherRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        service.cancelOrder(orderId, new CancelOrderRequest("khách hủy", "tại quầy"), actorId);

        assertEquals(OrderStatus.CANCELLED, order.getStatus());
        assertEquals(PaymentStatus.REFUNDED, order.getPaymentStatus()); // prepaid → REFUNDED (BR-08)
        assertEquals(0, customer.getPoints());                          // accrual clawed back (reversePoints)
        assertEquals(2, voucher.getTotalUsageCount());                  // one usage returned: 3 → 2
        verify(orderCancellationRepository).save(any());
        verify(customerRepository).save(any());                         // loyalty rollback persisted
        verify(voucherRepository).save(any());                          // voucher usage persisted
    }

    // ---- UC-75 refund / comp ------------------------------------------------

    @Test
    void refund_invalidPin_throws() {
        Order order = order(OrderStatus.COMPLETED, PaymentStatus.PAID);
        when(userRepository.findById(actorId)).thenReturn(Optional.of(actor()));
        when(orderRepository.findById(orderId)).thenReturn(Optional.of(order));
        when(userRepository.findByStoreId(storeId)).thenReturn(List.of(sm("9999")));

        RefundRequest req = new RefundRequest(RefundType.REFUND, new BigDecimal("30000"), "sai món", null, "0000");

        assertThrows(AppException.class, () -> service.refund(orderId, req, actorId));
        verify(orderRefundRepository, never()).save(any());
    }

    @Test
    void refund_cash_attachesToOpenDrawer_reversesPoints_BR09() {
        Order order = order(OrderStatus.COMPLETED, PaymentStatus.PAID);
        order.setPaymentMethod(PaymentMethod.CASH);
        order.setTotal(new BigDecimal("30000"));
        Customer customer = new Customer();
        customer.setId(UUID.randomUUID());
        customer.setPoints(10);
        order.setCustomer(customer);
        order.setPointsEarned(300);
        order.setPointsRedeemed(0);

        ShiftSession openShift = new ShiftSession();
        openShift.setId(UUID.randomUUID());
        openShift.setStatus(ShiftStatus.OPEN);

        when(userRepository.findById(actorId)).thenReturn(Optional.of(actor()));
        when(orderRepository.findById(orderId)).thenReturn(Optional.of(order));
        when(userRepository.findByStoreId(storeId)).thenReturn(List.of(sm("1234")));
        when(shiftSessionRepository.findFirstByStoreIdAndStatus(storeId, ShiftStatus.OPEN))
                .thenReturn(Optional.of(openShift));
        when(orderRefundRepository.save(any())).thenAnswer(inv -> {
            com.khoga.common.model.OrderRefund r = inv.getArgument(0);
            r.setId(UUID.randomUUID());
            return r;
        });

        RefundRequest req = new RefundRequest(RefundType.REFUND, null, "sai món", null, "1234");
        RefundResponse res = service.refund(orderId, req, actorId);

        assertEquals(PaymentStatus.REFUNDED, res.orderPaymentStatus());
        assertEquals(0, res.amount().compareTo(new BigDecimal("30000"))); // null amount → full total
        assertNull(res.remakeOrderId());
        assertEquals(0, customer.getPoints()); // 10 + 0 − 300, floored at 0
        verify(shiftSessionRepository).findFirstByStoreIdAndStatus(storeId, ShiftStatus.OPEN);
    }

    @Test
    void refund_compRemake_createsPendingClone() {
        Order order = order(OrderStatus.COMPLETED, PaymentStatus.PAID);
        order.setPaymentMethod(PaymentMethod.CASH);
        order.setSubtotal(new BigDecimal("30000"));

        MenuItem latte = new MenuItem();
        latte.setId(UUID.randomUUID());
        latte.setName("Latte");
        OrderItem line = new OrderItem();
        line.setId(UUID.randomUUID());
        line.setMenuItem(latte);
        line.setQuantity(1);
        line.setUnitPrice(new BigDecimal("30000"));

        when(userRepository.findById(actorId)).thenReturn(Optional.of(actor()));
        when(orderRepository.findById(orderId)).thenReturn(Optional.of(order));
        when(userRepository.findByStoreId(storeId)).thenReturn(List.of(sm("1234")));
        when(orderRefundRepository.save(any())).thenAnswer(inv -> {
            com.khoga.common.model.OrderRefund r = inv.getArgument(0);
            r.setId(UUID.randomUUID());
            return r;
        });
        when(shiftSessionRepository.findFirstByStoreIdAndStatus(storeId, ShiftStatus.OPEN))
                .thenReturn(Optional.empty());
        when(orderRepository.save(any())).thenAnswer(inv -> {
            Order o = inv.getArgument(0);
            if (o.getId() == null) {
                o.setId(UUID.randomUUID());
            }
            return o;
        });
        when(orderItemRepository.findByOrderId(orderId)).thenReturn(List.of(line));
        when(orderItemRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(orderItemToppingRepository.findByOrderItemId(line.getId())).thenReturn(List.of());

        RefundRequest req = new RefundRequest(RefundType.COMP_REMAKE, null, "làm lại", null, "1234");
        RefundResponse res = service.refund(orderId, req, actorId);

        assertEquals(RefundType.COMP_REMAKE, res.refundType());
        assertNotNull(res.remakeOrderId());
        assertEquals(0, res.amount().compareTo(BigDecimal.ZERO));
        assertEquals(PaymentStatus.PAID, order.getPaymentStatus()); // original untouched
        verify(orderItemRepository).save(any()); // line cloned
    }

    // ---- BR-88 auto-abandon -------------------------------------------------

    @Test
    void abandonStaleReadyOrders_usesReadyElapsedTime_andAudits_BR88() {
        Order stale = order(OrderStatus.READY, PaymentStatus.PAID);
        when(config.getGlobalInt(eq("READY_ABANDON_TIMEOUT"), eq(15))).thenReturn(15);
        // Abandon clock is measured from readyAt, not updatedAt (unrelated writes don't reset it).
        when(orderRepository.findByStatusAndReadyAtBefore(eq(OrderStatus.READY), any(LocalDateTime.class)))
                .thenReturn(List.of(stale));

        int count = service.abandonStaleReadyOrders();

        assertEquals(1, count);
        assertEquals(OrderStatus.ABANDONED, stale.getStatus());
        verify(auditLogService).record(any(), eq("Order"), eq(OrderStatus.READY.name()),
                eq(OrderStatus.ABANDONED.name()), any());
    }

    @Test
    void updateStatus_toReady_stampsReadyAt() {
        Order order = order(OrderStatus.PREPARING, PaymentStatus.PAID);
        when(userRepository.findById(actorId)).thenReturn(Optional.of(actor()));
        when(orderRepository.findById(orderId)).thenReturn(Optional.of(order));

        service.updateStatus(orderId, OrderStatus.READY, actorId);

        assertNotNull(order.getReadyAt()); // abandon clock starts at time-in-READY
    }

    @Test
    void forceAbandonReadyOrders_badPin_throws_noAbandon() {
        UUID sessionId = UUID.randomUUID();
        when(userRepository.findById(actorId)).thenReturn(Optional.of(actor()));
        when(userRepository.findByStoreId(storeId)).thenReturn(List.of(sm("1234")));

        assertThrows(AppException.class, () -> service.forceAbandonReadyOrders(sessionId, "0000", actorId));
        verify(orderRepository, never()).findByShiftSessionIdAndStatus(any(), any());
    }

    @Test
    void forceAbandonReadyOrders_smAuth_abandonsAndAudits_BR88() {
        UUID sessionId = UUID.randomUUID();
        Order ready = order(OrderStatus.READY, PaymentStatus.PAID);
        when(userRepository.findById(actorId)).thenReturn(Optional.of(actor()));
        when(userRepository.findByStoreId(storeId)).thenReturn(List.of(sm("1234")));
        when(orderRepository.findByShiftSessionIdAndStatus(sessionId, OrderStatus.READY))
                .thenReturn(List.of(ready));

        int count = service.forceAbandonReadyOrders(sessionId, "1234", actorId);

        assertEquals(1, count);
        assertEquals(OrderStatus.ABANDONED, ready.getStatus());
        verify(auditLogService).record(any(), eq("Order"), eq(OrderStatus.READY.name()),
                eq(OrderStatus.ABANDONED.name()), eq(actorId));
    }
}
