package com.khoga.pos;

import com.khoga.audit.AuditLogService;
import com.khoga.common.exception.AppException;
import com.khoga.common.model.Customer;
import com.khoga.common.model.MenuItem;
import com.khoga.common.model.Order;
import com.khoga.common.model.ShiftSession;
import com.khoga.common.model.Store;
import com.khoga.common.model.User;
import com.khoga.common.model.enums.OrderStatus;
import com.khoga.common.model.enums.PaymentMethod;
import com.khoga.common.model.enums.PaymentStatus;
import com.khoga.common.model.enums.ShiftStatus;
import com.khoga.common.repository.CustomerRepository;
import com.khoga.common.repository.MenuItemRepository;
import com.khoga.common.repository.OptionToppingRepository;
import com.khoga.common.repository.OrderItemRepository;
import com.khoga.common.repository.OrderItemToppingRepository;
import com.khoga.common.repository.OrderRepository;
import com.khoga.common.repository.ShiftSessionRepository;
import com.khoga.common.repository.UserRepository;
import com.khoga.common.repository.VoucherRepository;
import com.khoga.config.SystemConfigService;
import com.khoga.integration.EmailService;
import com.khoga.integration.PrinterService;
import com.khoga.integration.VietQrClient;
import com.khoga.pos.dto.CartLineRequest;
import com.khoga.pos.dto.CheckoutRequest;
import com.khoga.pos.dto.CheckoutResponse;
import com.khoga.pos.dto.DiscountBreakdown;
import com.khoga.pos.dto.VietQrCallbackRequest;
import com.khoga.voucher.VoucherValidationService;
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
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/** P2.2 unit tests for checkout: cash payment, insufficient cash, redeem multiple-of-100 (BR-74), VietQR late-callback guard (BR-85). */
@ExtendWith(MockitoExtension.class)
class CheckoutServiceTest {

    @Mock private ShiftSessionRepository shiftSessionRepository;
    @Mock private OrderRepository orderRepository;
    @Mock private OrderItemRepository orderItemRepository;
    @Mock private OrderItemToppingRepository orderItemToppingRepository;
    @Mock private MenuItemRepository menuItemRepository;
    @Mock private OptionToppingRepository optionToppingRepository;
    @Mock private CustomerRepository customerRepository;
    @Mock private VoucherRepository voucherRepository;
    @Mock private UserRepository userRepository;
    @Mock private VoucherValidationService voucherValidationService;
    @Mock private DiscountStackingEngine discountEngine;
    @Mock private SystemConfigService config;
    @Mock private VietQrClient vietQrClient;
    @Mock private PrinterService printerService;
    @Mock private AuditLogService auditLogService;
    @Mock private EmailService emailService;
    @InjectMocks private CheckoutService service;

    private final UUID actorId = UUID.randomUUID();
    private final UUID storeId = UUID.randomUUID();
    private final UUID menuItemId = UUID.randomUUID();

    private User cashier() {
        Store store = new Store();
        store.setId(storeId);
        User u = new User();
        u.setId(actorId);
        u.setStore(store);
        return u;
    }

    private ShiftSession openShift() {
        Store store = new Store();
        store.setId(storeId);
        ShiftSession s = new ShiftSession();
        s.setId(UUID.randomUUID());
        s.setStore(store);
        s.setStatus(ShiftStatus.OPEN);
        return s;
    }

    private MenuItem latte() {
        MenuItem mi = new MenuItem();
        mi.setId(menuItemId);
        mi.setName("Latte");
        mi.setPrice(new BigDecimal("30000"));
        mi.setIsActive(true);
        mi.setIsDeleted(false);
        return mi;
    }

    private void stubConfigAndEngine(DiscountBreakdown b, int redeemPoints) {
        when(config.getGlobalDecimal(eq("VAT_RATE"), any())).thenReturn(new BigDecimal("10"));
        when(config.getGlobalDecimal(eq("LOYALTY_REDEMPTION_VALUE_PER_POINT"), any())).thenReturn(new BigDecimal("100"));
        when(config.getGlobalDecimal(eq("LOYALTY_MAX_REDEMPTION_PERCENT"), any())).thenReturn(new BigDecimal("50"));
        when(config.getGlobalDecimal(eq("LOYALTY_MAX_REDEMPTION_LIMIT"), any())).thenReturn(new BigDecimal("100000"));
        when(config.getGlobalDecimal(eq("LOYALTY_ACCRUAL_PERCENTAGE"), any())).thenReturn(new BigDecimal("1"));
        when(discountEngine.compute(any(), any(), eq(redeemPoints), any())).thenReturn(b);
    }

    private DiscountBreakdown breakdown30k() {
        return new DiscountBreakdown(new BigDecimal("30000"), BigDecimal.ZERO, 0, BigDecimal.ZERO,
                new BigDecimal("30000"), new BigDecimal("2727"), new BigDecimal("30000"), 300);
    }

    @Test
    void submitCash_happyPath_paysAndReturnsChange() {
        when(userRepository.findById(actorId)).thenReturn(Optional.of(cashier()));
        when(shiftSessionRepository.findFirstByUserIdAndStatus(actorId, ShiftStatus.OPEN)).thenReturn(Optional.of(openShift()));
        when(menuItemRepository.findById(menuItemId)).thenReturn(Optional.of(latte()));
        stubConfigAndEngine(breakdown30k(), 0);
        when(orderRepository.save(any())).thenAnswer(inv -> {
            Order o = inv.getArgument(0);
            if (o.getId() == null) {
                o.setId(UUID.randomUUID());
            }
            return o;
        });
        when(orderItemRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        CheckoutRequest req = new CheckoutRequest(null, null, 0, PaymentMethod.CASH,
                new BigDecimal("50000"), List.of(new CartLineRequest(menuItemId, 1, null)));
        CheckoutResponse res = service.submitOrder(req, actorId);

        assertEquals(PaymentStatus.PAID, res.paymentStatus());
        assertEquals(0, res.changeDue().compareTo(new BigDecimal("20000")));
    }

    @Test
    void submitCash_insufficientCash_throws() {
        when(userRepository.findById(actorId)).thenReturn(Optional.of(cashier()));
        when(shiftSessionRepository.findFirstByUserIdAndStatus(actorId, ShiftStatus.OPEN)).thenReturn(Optional.of(openShift()));
        when(menuItemRepository.findById(menuItemId)).thenReturn(Optional.of(latte()));
        stubConfigAndEngine(breakdown30k(), 0);
        when(orderRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(orderItemRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        CheckoutRequest req = new CheckoutRequest(null, null, 0, PaymentMethod.CASH,
                new BigDecimal("10000"), List.of(new CartLineRequest(menuItemId, 1, null)));

        assertThrows(AppException.class, () -> service.submitOrder(req, actorId));
    }

    @Test
    void submitRedeemNotMultipleOf100_throws() {
        UUID customerId = UUID.randomUUID();
        Customer customer = new Customer();
        customer.setId(customerId);
        customer.setPoints(1000);
        when(userRepository.findById(actorId)).thenReturn(Optional.of(cashier()));
        when(shiftSessionRepository.findFirstByUserIdAndStatus(actorId, ShiftStatus.OPEN)).thenReturn(Optional.of(openShift()));
        when(customerRepository.findById(customerId)).thenReturn(Optional.of(customer));
        when(menuItemRepository.findById(menuItemId)).thenReturn(Optional.of(latte()));

        CheckoutRequest req = new CheckoutRequest(customerId, null, 150, PaymentMethod.CASH,
                new BigDecimal("50000"), List.of(new CartLineRequest(menuItemId, 1, null)));

        assertThrows(AppException.class, () -> service.submitOrder(req, actorId)); // BR-74 / MSG14
        verify(orderRepository, never()).save(any());
    }

    @Test
    void qrCallback_awaitingOrder_marksPaid_BR84() {
        UUID orderId = UUID.randomUUID();
        Order order = new Order();
        order.setId(orderId);
        order.setOrderNumber("OD-1");
        order.setStatus(OrderStatus.PENDING);
        order.setPaymentStatus(PaymentStatus.UNPAID);
        order.setTotal(new BigDecimal("30000"));
        when(orderRepository.findById(orderId)).thenReturn(Optional.of(order));

        service.handleQrCallback(new VietQrCallbackRequest(orderId, "ref-1"));

        assertEquals(PaymentStatus.PAID, order.getPaymentStatus());
    }

    @Test
    void qrCallback_cancelledOrder_notRevived_BR85() {
        UUID orderId = UUID.randomUUID();
        Store store = new Store();
        store.setId(storeId);
        store.setName("Branch 1");
        Order order = new Order();
        order.setId(orderId);
        order.setOrderNumber("OD-2");
        order.setStore(store);
        order.setStatus(OrderStatus.CANCELLED);
        order.setPaymentStatus(PaymentStatus.UNPAID);
        when(orderRepository.findById(orderId)).thenReturn(Optional.of(order));
        when(userRepository.findByStoreId(storeId)).thenReturn(List.of());

        service.handleQrCallback(new VietQrCallbackRequest(orderId, "ref-2"));

        assertEquals(PaymentStatus.UNPAID, order.getPaymentStatus()); // not revived
        verify(orderRepository, never()).save(any());
    }
}
