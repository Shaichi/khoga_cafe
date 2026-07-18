package com.khoga.config;

import com.khoga.common.model.*;
import com.khoga.common.model.enums.*;
import com.khoga.common.repository.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.*;
import java.util.concurrent.ThreadLocalRandom;
import java.util.stream.Collectors;

/**
 * First-run bootstrap (P0.6): seeds the global {@link SystemConfig} defaults, a sample {@link Store},
 * and the initial {@code ssadmin} super-admin (BR-82, {@code mustChangePassword=true}). Idempotent —
 * each item is only created when absent, so it is safe to run on every startup.
 *
 * <p>Disabled under the {@code prod} profile: the hardcoded bootstrap credentials (logged in clear)
 * are for dev/test only. Production provisioning is a P4 hardening item.
 */
@Slf4j
@Component
public class DataSeeder implements CommandLineRunner {

    static final String SEED_ADMIN_USERNAME = "ssadmin";
    /** Dev bootstrap password — meets BR-14 and must be changed on first login. */
    static final String SEED_ADMIN_PASSWORD = "Admin@123";
    static final String SEED_BIZADMIN_USERNAME = "bizadmin";
    /** Same dev bootstrap password (BR-14 compliant); must be changed on first login. */
    static final String SEED_BIZADMIN_PASSWORD = "Admin@123";
    static final String SEED_CEOVIEWER_USERNAME = "ceoviewer";
    /** Same dev bootstrap password (BR-14 compliant); must be changed on first login. */
    static final String SEED_CEOVIEWER_PASSWORD = "Admin@123";
    private static final String GLOBAL_SCOPE = "GLOBAL";

    private final UserRepository userRepository;
    private final StoreRepository storeRepository;
    private final SystemConfigRepository systemConfigRepository;
    private final PasswordEncoder passwordEncoder;
    private final CategoryRepository categoryRepository;
    private final MenuItemRepository menuItemRepository;
    private final RawMaterialRepository rawMaterialRepository;
    private final RecipeItemRepository recipeItemRepository;
    private final VoucherRepository voucherRepository;
    private final CustomerRepository customerRepository;
    private final ShiftSessionRepository shiftSessionRepository;
    private final OrderRepository orderRepository;
    private final OrderItemRepository orderItemRepository;
    private final StockItemRepository stockItemRepository;
    private final StockTransactionRepository stockTransactionRepository;

    public DataSeeder(UserRepository userRepository, StoreRepository storeRepository,
                      SystemConfigRepository systemConfigRepository, PasswordEncoder passwordEncoder,
                      CategoryRepository categoryRepository, MenuItemRepository menuItemRepository,
                      RawMaterialRepository rawMaterialRepository, RecipeItemRepository recipeItemRepository,
                      VoucherRepository voucherRepository, CustomerRepository customerRepository,
                      ShiftSessionRepository shiftSessionRepository, OrderRepository orderRepository,
                      OrderItemRepository orderItemRepository, StockItemRepository stockItemRepository,
                      StockTransactionRepository stockTransactionRepository) {
        this.userRepository = userRepository;
        this.storeRepository = storeRepository;
        this.systemConfigRepository = systemConfigRepository;
        this.passwordEncoder = passwordEncoder;
        this.categoryRepository = categoryRepository;
        this.menuItemRepository = menuItemRepository;
        this.rawMaterialRepository = rawMaterialRepository;
        this.recipeItemRepository = recipeItemRepository;
        this.voucherRepository = voucherRepository;
        this.customerRepository = customerRepository;
        this.shiftSessionRepository = shiftSessionRepository;
        this.orderRepository = orderRepository;
        this.orderItemRepository = orderItemRepository;
        this.stockItemRepository = stockItemRepository;
        this.stockTransactionRepository = stockTransactionRepository;
    }

    @Override
    @Transactional
    public void run(String... args) {
        seedSystemConfig();
        seedDefaultStore();
        seedSuperAdmin();
        seedBusinessAdmin();
        seedCeoViewer();
        seedStaff();
        seedRestaurantData();
    }

    private void seedSuperAdmin() {
        seedAdminUser(SEED_ADMIN_USERNAME, SEED_ADMIN_PASSWORD, Role.SSADMIN, "System Super Admin");
    }

    /** HQ businessadmin bootstrap (owns master data / promotions / loyalty adjustments — BR-49, UC-74). */
    private void seedBusinessAdmin() {
        seedAdminUser(SEED_BIZADMIN_USERNAME, SEED_BIZADMIN_PASSWORD, Role.BUSINESSADMIN, "Business Admin");
    }

    /** HQ ceoviewer bootstrap (read-only consolidated chain reports — SRS §2.1, BR-44). */
    private void seedCeoViewer() {
        seedAdminUser(SEED_CEOVIEWER_USERNAME, SEED_CEOVIEWER_PASSWORD, Role.CEOVIEWER, "CEO Viewer");
    }

    /** Creates an HQ bootstrap account if absent (idempotent); {@code mustChangePassword=true} per BR-82. */
    private void seedAdminUser(String username, String rawPassword, Role role, String fullName) {
        if (userRepository.findByUsername(username).isPresent()) {
            log.info("[seed] {} already present — skipping", username);
            return;
        }
        User user = new User();
        user.setUsername(username);
        user.setPasswordHash(passwordEncoder.encode(rawPassword));
        user.setRole(role);
        user.setFullName(fullName);
        user.setIsActive(true);
        user.setMustChangePassword(true);   // BR-82
        user.setFailedAttempts(0);
        userRepository.save(user);
        log.warn("[seed] Created bootstrap {} (username='{}', password='{}') — CHANGE ON FIRST LOGIN",
                role, username, rawPassword);
    }

    private void seedDefaultStore() {
        if (storeRepository.count() > 0) {
            return;
        }
        Store store = new Store();
        store.setName("Khoga Flagship");
        store.setAddress("123 Coffee Street");
        store.setPhone("0900000000");
        store.setIsActive(true);
        storeRepository.save(store);
        log.info("[seed] Created default store '{}'", store.getName());
    }

    private void seedSystemConfig() {
        Map<String, String> defaults = new LinkedHashMap<>();
        defaults.put("VAT_RATE", "10");                         // BR-45 (VAT inclusive 10/110), BR-70
        defaults.put("LOYALTY_ACCRUAL_PERCENTAGE", "1");        // BR-01 / BR-94
        defaults.put("LOYALTY_REDEMPTION_VALUE_PER_POINT", "100"); // BR-74 / BR-94
        defaults.put("LOYALTY_MAX_REDEMPTION_PERCENT", "50");   // BR-02 / BR-94
        defaults.put("LOYALTY_MAX_REDEMPTION_LIMIT", "100000"); // BR-02 / BR-94 (max VND discount/order)
        defaults.put("MAX_ACTIVE_BRANCHES", "5");               // BR-54
        defaults.put("HQ_MFA_REQUIRED", "true");                // BR-83
        defaults.put("CANCEL_REFUND_ALERT_THRESHOLD", "5");     // BR-79 / BR-94 (% of orders)
        defaults.put("LOYALTY_EXPIRY_MONTHS", "12");            // BR-35 (P4 — point inactivity expiry)
        defaults.put("CUSTOMER_PII_RETENTION_MONTHS", "24");    // BR-72 (P4 — PDPA anonymisation)
        defaults.put("ATTENDANCE_PIN_MAX_ATTEMPTS", "5");       // BR-93 (terminal PIN lockout threshold)
        defaults.put("ATTENDANCE_PIN_LOCK_MINUTES", "15");      // BR-93 (terminal PIN lockout cooldown)

        Set<String> existing = systemConfigRepository.findAll().stream()
                .filter(c -> GLOBAL_SCOPE.equals(c.getScope()))
                .map(SystemConfig::getConfigKey)
                .collect(Collectors.toSet());

        defaults.forEach((key, value) -> {
            if (existing.contains(key)) {
                return;
            }
            SystemConfig cfg = new SystemConfig();
            cfg.setConfigKey(key);
            cfg.setConfigValue(value);
            cfg.setScope(GLOBAL_SCOPE);
            cfg.setUpdatedBy("seed");
            systemConfigRepository.save(cfg);
            log.info("[seed] SystemConfig {}={}", key, value);
        });
    }

    private void seedStaff() {
        Store store = storeRepository.findAll().stream().findFirst().orElse(null);
        if (store == null) {
            log.error("[seed] No store found to associate staff!");
            return;
        }
        seedStaffUser("cashier", "Admin@123", Role.CASHIER, "Default Cashier", store, "EMP-001");
        seedStaffUser("manager", "Admin@123", Role.STORE_MANAGER, "Default Store Manager", store, "EMP-002");
        seedStaffUser("barista", "Admin@123", Role.BARISTA, "Default Barista", store, "EMP-003");
    }

    private void seedStaffUser(String username, String rawPassword, Role role, String fullName, Store store, String employeeId) {
        if (userRepository.findByUsername(username).isPresent()) {
            log.info("[seed] Staff {} already present — skipping", username);
            return;
        }
        User user = new User();
        user.setUsername(username);
        user.setPasswordHash(passwordEncoder.encode(rawPassword));
        user.setRole(role);
        user.setFullName(fullName);
        user.setIsActive(true);
        user.setMustChangePassword(false);
        user.setFailedAttempts(0);
        user.setStore(store);
        user.setEmployeeId(employeeId);
        user.setAttendancePin("1234");
        userRepository.save(user);
        log.warn("[seed] Created staff {} (username='{}', password='{}')", role, username, rawPassword);
    }

    private void seedRestaurantData() {
        if (categoryRepository.count() > 0) {
            log.info("[seed] Restaurant data already seeded - skipping");
            return;
        }

        log.info("[seed] Seeding realistic restaurant data...");

        // 1. Categories
        Category caPhe = new Category();
        caPhe.setName("Cà phê");
        caPhe.setDescription("Các loại cà phê thơm ngon");
        caPhe.setIsActive(true);
        caPhe = categoryRepository.save(caPhe);

        Category traSua = new Category();
        traSua.setName("Trà sữa");
        traSua.setDescription("Trà sữa đậm vị kem béo");
        traSua.setIsActive(true);
        traSua = categoryRepository.save(traSua);

        Category traTraiCay = new Category();
        traTraiCay.setName("Trà trái cây");
        traTraiCay.setDescription("Trà thanh mát kết hợp trái cây tươi");
        traTraiCay.setIsActive(true);
        traTraiCay = categoryRepository.save(traTraiCay);

        Category banhNgot = new Category();
        banhNgot.setName("Bánh ngọt");
        banhNgot.setDescription("Bánh nướng nóng hổi mỗi ngày");
        banhNgot.setIsActive(true);
        banhNgot = categoryRepository.save(banhNgot);

        // 2. Raw Materials
        RawMaterial rmCoffee = createRawMaterial("RM-COFFEE", "Hạt cà phê", "kg", 2.0, 150000);
        RawMaterial rmCondMilk = createRawMaterial("RM-COND-MILK", "Sữa đặc", "hộp", 5.0, 20000);
        RawMaterial rmFreshMilk = createRawMaterial("RM-FRESH-MILK", "Sữa tươi", "L", 10.0, 30000);
        RawMaterial rmBlackTea = createRawMaterial("RM-BLACK-TEA", "Trà đen", "kg", 1.0, 120000);
        RawMaterial rmPeach = createRawMaterial("RM-PEACH", "Đào miếng", "hộp", 4.0, 50000);
        RawMaterial rmSugar = createRawMaterial("RM-SUGAR", "Đường nước", "kg", 3.0, 25000);
        RawMaterial rmPearl = createRawMaterial("RM-PEARL", "Trân châu", "kg", 2.0, 40000);

        // 3. Menu Items
        MenuItem capheDen = createMenuItem(caPhe, "Cà phê đen đá", 25000, "Cà phê đen truyền thống đậm đà", "CFD", "CFD-S", "S");
        MenuItem capheSua = createMenuItem(caPhe, "Cà phê sữa đá", 29000, "Cà phê kết hợp sữa đặc béo ngậy", "CFS", "CFS-S", "S");
        MenuItem traDao = createMenuItem(traTraiCay, "Trà đào cam sả", 39000, "Trà đào thơm nức hương sả và cam tươi", "TDC", "TDC-M", "M");
        MenuItem traSuaTC = createMenuItem(traSua, "Trà sữa trân châu", 39000, "Trà sữa truyền thống kèm trân châu dai giòn", "TSTC", "TSTC-M", "M");
        MenuItem croissant = createMenuItem(banhNgot, "Bánh Croissant", 22000, "Bánh sừng bò bơ Pháp giòn rụm", "CRS", "CRS-S", "S");

        // 4. Recipes
        createRecipe(capheDen, rmCoffee, 0.02);
        createRecipe(capheDen, rmSugar, 0.015);

        createRecipe(capheSua, rmCoffee, 0.02);
        createRecipe(capheSua, rmCondMilk, 0.05);

        createRecipe(traDao, rmBlackTea, 0.015);
        createRecipe(traDao, rmPeach, 0.1);
        createRecipe(traDao, rmSugar, 0.02);

        createRecipe(traSuaTC, rmBlackTea, 0.02);
        createRecipe(traSuaTC, rmFreshMilk, 0.1);
        createRecipe(traSuaTC, rmSugar, 0.025);
        createRecipe(traSuaTC, rmPearl, 0.05);

        // 5. Stock Items
        Store store = storeRepository.findAll().stream().findFirst().orElseThrow();
        Map<UUID, StockItem> stockMap = new HashMap<>();
        
        List<RawMaterial> allMaterials = Arrays.asList(rmCoffee, rmCondMilk, rmFreshMilk, rmBlackTea, rmPeach, rmSugar, rmPearl);
        List<BigDecimal> initialQtys = Arrays.asList(
            new BigDecimal("15.0"), new BigDecimal("40.0"), new BigDecimal("50.0"), 
            new BigDecimal("10.0"), new BigDecimal("30.0"), new BigDecimal("25.0"), new BigDecimal("15.0")
        );

        for (int i = 0; i < allMaterials.size(); i++) {
            RawMaterial rm = allMaterials.get(i);
            StockItem si = new StockItem();
            si.setStore(store);
            si.setRawMaterial(rm);
            si.setCurrentQuantity(initialQtys.get(i));
            si.setMinAlertThreshold(rm.getSuggestedMinThreshold());
            si = stockItemRepository.save(si);
            stockMap.put(rm.getId(), si);
        }

        // 6. Vouchers
        Voucher v1 = new Voucher();
        v1.setCode("GIAM10K");
        v1.setDescription("Giảm ngay 10k");
        v1.setDiscountType(DiscountType.FIXED_AMOUNT);
        v1.setDiscountValue(new BigDecimal("10000"));
        v1.setMinOrderValue(new BigDecimal("50000"));
        v1.setIsActive(true);
        v1 = voucherRepository.save(v1);

        Voucher v2 = new Voucher();
        v2.setCode("CHAOBAN");
        v2.setDescription("Giảm 15% tối đa 30k");
        v2.setDiscountType(DiscountType.PERCENTAGE);
        v2.setDiscountValue(new BigDecimal("15"));
        v2.setMinOrderValue(new BigDecimal("30000"));
        v2.setMaxDiscountAmount(new BigDecimal("30000"));
        v2.setIsActive(true);
        v2 = voucherRepository.save(v2);

        // 7. Customers
        Customer c1 = createCustomer("Nguyễn Văn An", "anva@gmail.com", "0911222333", 150);
        Customer c2 = createCustomer("Trần Thị Bình", "binhtt@gmail.com", "0922333444", 80);
        Customer c3 = createCustomer("Lê Hoàng Nam", "namlh@gmail.com", "0933444555", 10);
        List<Customer> customerList = Arrays.asList(c1, c2, c3);

        // 8. Cashier user
        User cashierUser = userRepository.findByUsername("cashier").orElseThrow();

        // 9. Shift Session
        LocalDateTime todayStart = LocalDate.now().atTime(7, 30);
        LocalDateTime todayEnd = LocalDate.now().atTime(22, 0);

        ShiftSession shift = new ShiftSession();
        shift.setStore(store);
        shift.setUser(cashierUser);
        shift.setStartTime(todayStart);
        shift.setStartingCash(new BigDecimal("1000000"));
        shift.setStatus(ShiftStatus.OPEN);
        shift.setPosRegisterId("POS-01");
        shift = shiftSessionRepository.save(shift);

        // 10. Simulate 50 Orders
        List<MenuItem> menuList = Arrays.asList(capheDen, capheSua, traDao, traSuaTC, croissant);
        Random random = ThreadLocalRandom.current();
        BigDecimal totalCashSales = BigDecimal.ZERO;

        for (int i = 1; i <= 50; i++) {
            Order order = new Order();
            order.setStore(store);
            order.setOrderNumber(String.format("ORD-%04d", i));
            order.setShiftSession(shift);
            order.setOrderType(random.nextBoolean() ? OrderType.DINE_IN : OrderType.TAKEAWAY);
            
            if (random.nextInt(10) < 4) {
                order.setCustomer(customerList.get(random.nextInt(customerList.size())));
            }

            int hour = 8 + (i * 13 / 50); // spreads from 8am to 9pm
            int minute = (i * 17) % 60;
            order.setCreatedAt(LocalDate.now().atTime(hour, minute));
            order.setUpdatedAt(order.getCreatedAt());

            int numItems = random.nextInt(2) + 1;
            List<OrderItem> items = new ArrayList<>();
            BigDecimal subtotal = BigDecimal.ZERO;

            for (int k = 0; k < numItems; k++) {
                MenuItem menu = menuList.get(random.nextInt(menuList.size()));
                int qty = random.nextInt(2) + 1;
                
                OrderItem item = new OrderItem();
                item.setOrder(order);
                item.setMenuItem(menu);
                item.setQuantity(qty);
                item.setUnitPrice(menu.getPrice());
                item.setCreatedAt(order.getCreatedAt());
                item.setUpdatedAt(order.getCreatedAt());
                subtotal = subtotal.add(menu.getPrice().multiply(new BigDecimal(qty)));
                items.add(item);
            }

            order.setSubtotal(subtotal);

            BigDecimal discount = BigDecimal.ZERO;
            if (random.nextInt(100) < 15) {
                Voucher v = random.nextBoolean() ? v1 : v2;
                if (subtotal.compareTo(v.getMinOrderValue()) >= 0) {
                    order.setVoucher(v);
                    if (v.getDiscountType() == DiscountType.FIXED_AMOUNT) {
                        discount = v.getDiscountValue();
                    } else { // PERCENTAGE
                        discount = subtotal.multiply(v.getDiscountValue().divide(new BigDecimal("100"), 4, RoundingMode.HALF_UP));
                        if (v.getMaxDiscountAmount() != null && discount.compareTo(v.getMaxDiscountAmount()) > 0) {
                            discount = v.getMaxDiscountAmount();
                        }
                    }
                }
            }
            order.setDiscount(discount);

            BigDecimal taxable = subtotal.subtract(discount);
            BigDecimal tax = taxable.multiply(new BigDecimal("0.1")).setScale(0, RoundingMode.HALF_UP);
            order.setTaxAmount(tax);

            BigDecimal total = taxable.add(tax);
            order.setTotal(total);

            int pmChance = random.nextInt(10);
            if (pmChance < 4) {
                order.setPaymentMethod(PaymentMethod.CASH);
                totalCashSales = totalCashSales.add(total);
            } else if (pmChance < 7) {
                order.setPaymentMethod(PaymentMethod.CARD);
            } else {
                order.setPaymentMethod(PaymentMethod.VIETQR);
                order.setTransactionRef(UUID.randomUUID().toString().substring(0, 12).toUpperCase());
            }

            order.setPaymentStatus(PaymentStatus.PAID);
            order.setStatus(OrderStatus.COMPLETED);
            order.setPointsEarned(total.divide(new BigDecimal("10000"), 0, RoundingMode.DOWN).intValue());
            
            orderRepository.save(order);
            
            for (OrderItem oi : items) {
                orderItemRepository.save(oi);
                
                List<RecipeItem> recipes = recipeItemRepository.findByMenuItemId(oi.getMenuItem().getId());
                for (RecipeItem recipe : recipes) {
                    StockItem si = stockMap.get(recipe.getRawMaterial().getId());
                    if (si != null) {
                        BigDecimal before = si.getCurrentQuantity();
                        BigDecimal deduction = recipe.getQuantityRequired().multiply(new BigDecimal(oi.getQuantity()));
                        BigDecimal after = before.subtract(deduction);
                        si.setCurrentQuantity(after);
                        stockItemRepository.save(si);

                        StockTransaction tx = new StockTransaction();
                        tx.setStockItem(si);
                        tx.setManager(cashierUser);
                        tx.setTransactionType(TransactionType.RECIPE_DEDUCTION);
                        tx.setQuantity(deduction.negate());
                        tx.setQuantityBefore(before);
                        tx.setQuantityAfter(after);
                        tx.setReason("Bán hàng " + order.getOrderNumber());
                        tx.setCreatedAt(order.getCreatedAt());
                        tx.setUpdatedAt(order.getCreatedAt());
                        stockTransactionRepository.save(tx);
                    }
                }
            }
        }

        shift.setEndTime(todayEnd);
        shift.setEndingCash(shift.getStartingCash().add(totalCashSales));
        shift.setStatus(ShiftStatus.CLOSED);
        shift.setUpdatedAt(todayEnd);
        shiftSessionRepository.save(shift);

        log.info("[seed] Successfully seeded 50 realistic coffee shop orders!");
    }

    private RawMaterial createRawMaterial(String code, String name, String unit, double minThreshold, double stdCost) {
        RawMaterial rm = new RawMaterial();
        rm.setCode(code);
        rm.setName(name);
        rm.setUnit(unit);
        rm.setSuggestedMinThreshold(new BigDecimal(minThreshold));
        rm.setStandardCost(new BigDecimal(stdCost));
        rm.setIsActive(true);
        rm.setCategory("Chung");
        return rawMaterialRepository.save(rm);
    }

    private MenuItem createMenuItem(Category category, String name, double price, String desc, String code, String sku, String size) {
        MenuItem m = new MenuItem();
        m.setCategory(category);
        m.setName(name);
        m.setPrice(new BigDecimal(price));
        m.setDescription(desc);
        m.setIsActive(true);
        m.setBarcode(code);
        m.setAbbreviation(code);
        m.setIsDeleted(false);
        m.setSku(sku);
        m.setSizeName(size);
        return menuItemRepository.save(m);
    }

    private void createRecipe(MenuItem menu, RawMaterial rm, double qty) {
        RecipeItem ri = new RecipeItem();
        ri.setMenuItem(menu);
        ri.setRawMaterial(rm);
        ri.setQuantityRequired(new BigDecimal(qty));
        recipeItemRepository.save(ri);
    }

    private Customer createCustomer(String name, String email, String phone, int points) {
        Customer c = new Customer();
        c.setFullName(name);
        c.setEmail(email);
        c.setPhone(phone);
        c.setPoints(points);
        c.setIsActive(true);
        c.setConsentAt(LocalDateTime.now());
        c.setConsentVersion("1.0");
        return customerRepository.save(c);
    }
}
