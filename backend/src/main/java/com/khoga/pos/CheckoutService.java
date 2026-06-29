package com.khoga.pos;

import com.khoga.audit.AuditLogService;
import com.khoga.common.exception.AppException;
import com.khoga.common.exception.ResourceNotFoundException;
import com.khoga.common.model.Customer;
import com.khoga.common.model.MenuItem;
import com.khoga.common.model.Order;
import com.khoga.common.model.OrderItem;
import com.khoga.common.model.OrderItemTopping;
import com.khoga.common.model.OptionTopping;
import com.khoga.common.model.ShiftSession;
import com.khoga.common.model.Store;
import com.khoga.common.model.User;
import com.khoga.common.model.Voucher;
import com.khoga.common.model.enums.ActionType;
import com.khoga.common.model.enums.OrderStatus;
import com.khoga.common.model.enums.OrderType;
import com.khoga.common.model.enums.PaymentStatus;
import com.khoga.common.model.enums.Role;
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
import com.khoga.integration.VietQrPayment;
import com.khoga.pos.dto.CartLineRequest;
import com.khoga.pos.dto.CheckoutRequest;
import com.khoga.pos.dto.CheckoutResponse;
import com.khoga.pos.dto.DiscountBreakdown;
import com.khoga.pos.dto.DiscountConfig;
import com.khoga.pos.dto.VietQrCallbackRequest;
import com.khoga.voucher.VoucherValidationService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.UUID;

/**
 * POS checkout pipeline (UC-48/49/50/51). Stateless: the client posts the whole cart. Pricing →
 * voucher validation (BR-42/52) → loyalty redemption validation (BR-02/74) → {@link DiscountStackingEngine}
 * (BR-70) → create {@code Order(PENDING)} + lines. CASH/CARD finalize immediately; VIETQR returns a QR
 * and finalizes on the gateway callback (auto-confirm BR-84) with a late-callback guard (BR-85).
 */
@Slf4j
@Service
public class CheckoutService {

    private final ShiftSessionRepository shiftSessionRepository;
    private final OrderRepository orderRepository;
    private final OrderItemRepository orderItemRepository;
    private final OrderItemToppingRepository orderItemToppingRepository;
    private final MenuItemRepository menuItemRepository;
    private final OptionToppingRepository optionToppingRepository;
    private final CustomerRepository customerRepository;
    private final VoucherRepository voucherRepository;
    private final UserRepository userRepository;
    private final VoucherValidationService voucherValidationService;
    private final DiscountStackingEngine discountEngine;
    private final SystemConfigService config;
    private final VietQrClient vietQrClient;
    private final PrinterService printerService;
    private final AuditLogService auditLogService;
    private final EmailService emailService;

    public CheckoutService(ShiftSessionRepository shiftSessionRepository, OrderRepository orderRepository,
                           OrderItemRepository orderItemRepository, OrderItemToppingRepository orderItemToppingRepository,
                           MenuItemRepository menuItemRepository, OptionToppingRepository optionToppingRepository,
                           CustomerRepository customerRepository, VoucherRepository voucherRepository,
                           UserRepository userRepository, VoucherValidationService voucherValidationService,
                           DiscountStackingEngine discountEngine, SystemConfigService config,
                           VietQrClient vietQrClient, PrinterService printerService,
                           AuditLogService auditLogService, EmailService emailService) {
        this.shiftSessionRepository = shiftSessionRepository;
        this.orderRepository = orderRepository;
        this.orderItemRepository = orderItemRepository;
        this.orderItemToppingRepository = orderItemToppingRepository;
        this.menuItemRepository = menuItemRepository;
        this.optionToppingRepository = optionToppingRepository;
        this.customerRepository = customerRepository;
        this.voucherRepository = voucherRepository;
        this.userRepository = userRepository;
        this.voucherValidationService = voucherValidationService;
        this.discountEngine = discountEngine;
        this.config = config;
        this.vietQrClient = vietQrClient;
        this.printerService = printerService;
        this.auditLogService = auditLogService;
        this.emailService = emailService;
    }

    /** UC-48/49 preview — compute the BR-70 breakdown without persisting. */
    @Transactional(readOnly = true)
    public DiscountBreakdown preview(CheckoutRequest req, UUID actorId) {
        currentUser(actorId);
        Customer customer = req.customerId() == null ? null
                : customerRepository.findById(req.customerId()).orElse(null);
        BigDecimal gross = priceCart(req.items());
        BigDecimal voucherDiscount = voucherDiscount(req.voucherCode(), gross);
        validateRedeem(req, customer);
        return discountEngine.compute(gross, voucherDiscount, req.redeemPoints(), buildConfig());
    }

    /** UC-51 submit order + take payment. */
    @Transactional
    public CheckoutResponse submitOrder(CheckoutRequest req, UUID actorId) {
        currentUser(actorId);
        ShiftSession shift = shiftSessionRepository.findFirstByUserIdAndStatus(actorId, ShiftStatus.OPEN)
                .orElseThrow(() -> new AppException("Bạn cần mở ca trước khi bán hàng")); // UC-44 precondition
        Customer customer = req.customerId() == null ? null
                : customerRepository.findById(req.customerId())
                    .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy khách hàng"));

        BigDecimal gross = priceCart(req.items());
        Voucher voucher = resolveVoucher(req.voucherCode());
        BigDecimal voucherDiscount = voucher == null ? BigDecimal.ZERO
                : voucherValidationService.validate(voucher.getCode(), gross, 0); // per-customer usage tracking: P2.3
        validateRedeem(req, customer);

        DiscountConfig cfg = buildConfig();
        DiscountBreakdown b = discountEngine.compute(gross, voucherDiscount, req.redeemPoints(), cfg);
        int pointsConsumed = pointsConsumed(b.pointDiscount(), cfg.valuePerPoint());

        Order order = new Order();
        order.setStore(shift.getStore());
        order.setShiftSession(shift);
        order.setCustomer(customer);
        order.setVoucher(voucher);
        order.setOrderType(OrderType.TAKEAWAY);
        order.setOrderNumber("OD-" + System.currentTimeMillis());
        order.setSubtotal(b.grossSubtotal());
        order.setDiscount(b.voucherDiscount().add(b.pointDiscount()));
        order.setTaxAmount(b.taxAmount());
        order.setTotal(b.netTotalPayable());
        order.setStatus(OrderStatus.PENDING);
        order.setPaymentMethod(req.paymentMethod());
        order.setPaymentStatus(PaymentStatus.UNPAID);
        order.setPointsRedeemed(pointsConsumed);
        order.setPointsEarned(b.pointsEarned());
        Order saved = orderRepository.save(order);
        persistLines(saved, req.items());

        return switch (req.paymentMethod()) {
            case CASH -> {
                if (req.cashReceived() == null || req.cashReceived().compareTo(saved.getTotal()) < 0) {
                    throw new AppException("Tiền khách đưa không đủ");
                }
                finalizePaid(saved, actorId);
                yield response(saved, b, req.cashReceived().subtract(saved.getTotal()), null);
            }
            case CARD -> {
                finalizePaid(saved, actorId);
                yield response(saved, b, BigDecimal.ZERO, null);
            }
            case VIETQR -> {
                VietQrPayment qr = vietQrClient.generateQr(saved.getId(), saved.getTotal()); // idempotency = orderId (BR-84)
                yield response(saved, b, null, qr);
            }
            default -> throw new AppException("Phương thức thanh toán không hỗ trợ");
        };
    }

    /** VietQR webhook (BR-84 auto-confirm) with late-callback guard (BR-85). */
    @Transactional
    public void handleQrCallback(VietQrCallbackRequest req) {
        Order order = orderRepository.findById(req.orderId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đơn"));
        boolean awaiting = order.getPaymentStatus() == PaymentStatus.UNPAID
                && order.getStatus() == OrderStatus.PENDING;
        if (awaiting) {
            finalizePaid(order, null); // system actor
            log.info("[VietQR] Order {} marked PAID via callback (ref {})", order.getId(), req.reference());
        } else {
            // BR-85: do not revive a cancelled/timed-out order — route to reconciliation + alert SM
            log.warn("[BR-85] Late VietQR callback for non-awaiting order {} (status={}, payment={}) ref {} — flagged for refund",
                    order.getId(), order.getStatus(), order.getPaymentStatus(), req.reference());
            alertReconciliation(order, req.reference());
        }
    }

    private void finalizePaid(Order order, UUID actorId) {
        order.setPaymentStatus(PaymentStatus.PAID);
        orderRepository.save(order);

        Customer c = order.getCustomer();
        if (c != null) {
            int balance = nz(c.getPoints());
            balance -= nz(order.getPointsRedeemed());   // BR-02 redemption
            balance += nz(order.getPointsEarned());     // BR-01 accrual
            c.setPoints(Math.max(balance, 0));
            customerRepository.save(c);
        }
        Voucher v = order.getVoucher();
        if (v != null) {
            v.setTotalUsageCount(nz(v.getTotalUsageCount()) + 1);
            voucherRepository.save(v);
        }
        // BR-80: audit every voucher application + point redemption at checkout
        String json = "{\"orderId\":\"" + order.getId() + "\",\"voucher\":\""
                + (v != null ? v.getCode() : "") + "\",\"pointsRedeemed\":" + nz(order.getPointsRedeemed())
                + ",\"pointsEarned\":" + nz(order.getPointsEarned()) + "}";
        auditLogService.record(ActionType.CREATE, "Checkout", null, json, actorId);

        printerService.printReceipt("Receipt " + order.getOrderNumber() + " — total " + order.getTotal());
        printerService.printLabel("Order " + order.getOrderNumber());
    }

    private void persistLines(Order order, List<CartLineRequest> items) {
        for (CartLineRequest line : items) {
            MenuItem mi = menuItemRepository.findById(line.menuItemId())
                    .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy món"));
            OrderItem oi = new OrderItem();
            oi.setOrder(order);
            oi.setMenuItem(mi);
            oi.setQuantity(line.quantity());
            oi.setUnitPrice(mi.getPrice());
            OrderItem savedItem = orderItemRepository.save(oi);
            if (line.toppingIds() != null) {
                for (UUID toppingId : line.toppingIds()) {
                    OptionTopping topping = optionToppingRepository.findById(toppingId)
                            .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy topping"));
                    OrderItemTopping ot = new OrderItemTopping();
                    ot.setOrderItem(savedItem);
                    ot.setTopping(topping);
                    ot.setQuantity(line.quantity());
                    ot.setUnitPrice(topping.getPrice());
                    orderItemToppingRepository.save(ot);
                }
            }
        }
    }

    private BigDecimal priceCart(List<CartLineRequest> items) {
        BigDecimal gross = BigDecimal.ZERO;
        for (CartLineRequest line : items) {
            MenuItem mi = menuItemRepository.findById(line.menuItemId())
                    .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy món"));
            if (Boolean.TRUE.equals(mi.getIsDeleted()) || Boolean.FALSE.equals(mi.getIsActive())) {
                throw new AppException("Món '" + mi.getName() + "' không khả dụng"); // BR-25 chain-active
            }
            BigDecimal unit = nzb(mi.getPrice());
            if (line.toppingIds() != null) {
                for (UUID toppingId : line.toppingIds()) {
                    OptionTopping topping = optionToppingRepository.findById(toppingId)
                            .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy topping"));
                    unit = unit.add(nzb(topping.getPrice()));
                }
            }
            gross = gross.add(unit.multiply(BigDecimal.valueOf(line.quantity())));
        }
        return gross;
    }

    private DiscountConfig buildConfig() {
        return new DiscountConfig(
                config.getGlobalDecimal("VAT_RATE", new BigDecimal("10")),
                config.getGlobalDecimal("LOYALTY_REDEMPTION_VALUE_PER_POINT", new BigDecimal("100")),
                config.getGlobalDecimal("LOYALTY_MAX_REDEMPTION_PERCENT", new BigDecimal("50")),
                config.getGlobalDecimal("LOYALTY_MAX_REDEMPTION_LIMIT", new BigDecimal("100000")),
                config.getGlobalDecimal("LOYALTY_ACCRUAL_PERCENTAGE", new BigDecimal("1")));
    }

    private Voucher resolveVoucher(String code) {
        if (!StringUtils.hasText(code)) {
            return null;
        }
        return voucherRepository.findByCode(code)
                .orElseThrow(() -> new AppException("Mã giảm giá không tồn tại"));
    }

    private BigDecimal voucherDiscount(String code, BigDecimal gross) {
        if (!StringUtils.hasText(code)) {
            return BigDecimal.ZERO;
        }
        return voucherValidationService.validate(code, gross, 0);
    }

    private void validateRedeem(CheckoutRequest req, Customer customer) {
        if (req.redeemPoints() <= 0) {
            return;
        }
        if (customer == null) {
            throw new AppException("Cần chọn khách hàng để đổi điểm");
        }
        if (req.redeemPoints() % 100 != 0) {
            throw AppException.of("MSG14"); // BR-74 — redemption must be a multiple of 100
        }
        if (nz(customer.getPoints()) < req.redeemPoints()) {
            throw AppException.of("MSG11"); // insufficient points balance
        }
    }

    private int pointsConsumed(BigDecimal pointDiscount, BigDecimal valuePerPoint) {
        if (pointDiscount == null || pointDiscount.signum() <= 0 || valuePerPoint == null || valuePerPoint.signum() <= 0) {
            return 0;
        }
        return pointDiscount.divide(valuePerPoint, 0, RoundingMode.FLOOR).intValueExact();
    }

    private void alertReconciliation(Order order, String reference) {
        Store store = order.getStore();
        if (store == null) {
            return;
        }
        String body = "Callback VietQR đến đơn đã đóng/huỷ " + order.getOrderNumber()
                + " (ref " + reference + "). Cần đối soát & hoàn tiền.";
        userRepository.findByStoreId(store.getId()).stream()
                .filter(u -> u.getRole() == Role.STORE_MANAGER)
                .filter(u -> Boolean.TRUE.equals(u.getIsActive()))
                .filter(u -> u.getEmail() != null && !u.getEmail().isBlank())
                .forEach(sm -> emailService.send(sm.getEmail(),
                        "[BR-85] Đối soát thanh toán VietQR — " + store.getName(), body));
    }

    private CheckoutResponse response(Order o, DiscountBreakdown b, BigDecimal change, VietQrPayment qr) {
        return new CheckoutResponse(o.getId(), o.getOrderNumber(), o.getStatus(), o.getPaymentStatus(),
                o.getPaymentMethod(), b, change,
                qr != null ? qr.qrContent() : null, qr != null ? qr.reference() : null);
    }

    private User currentUser(UUID actorId) {
        return userRepository.findById(actorId)
                .orElseThrow(() -> new AppException("Yêu cầu xác thực"));
    }

    private static int nz(Integer v) {
        return v == null ? 0 : v;
    }

    private static BigDecimal nzb(BigDecimal v) {
        return v == null ? BigDecimal.ZERO : v;
    }
}
