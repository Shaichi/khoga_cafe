package com.khoga.config;

import com.khoga.common.model.Store;
import com.khoga.common.model.SystemConfig;
import com.khoga.common.model.User;
import com.khoga.common.model.enums.Role;
import com.khoga.common.repository.StoreRepository;
import com.khoga.common.repository.SystemConfigRepository;
import com.khoga.common.repository.UserRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;
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
@Profile("!prod")
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

    public DataSeeder(UserRepository userRepository, StoreRepository storeRepository,
                      SystemConfigRepository systemConfigRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.storeRepository = storeRepository;
        this.systemConfigRepository = systemConfigRepository;
        this.passwordEncoder = passwordEncoder;
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
}
