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
    }

    private void seedSuperAdmin() {
        if (userRepository.findByUsername(SEED_ADMIN_USERNAME).isPresent()) {
            log.info("[seed] ssadmin already present — skipping");
            return;
        }
        User admin = new User();
        admin.setUsername(SEED_ADMIN_USERNAME);
        admin.setPasswordHash(passwordEncoder.encode(SEED_ADMIN_PASSWORD));
        admin.setRole(Role.SSADMIN);
        admin.setFullName("System Super Admin");
        admin.setIsActive(true);
        admin.setMustChangePassword(true);   // BR-82
        admin.setFailedAttempts(0);
        userRepository.save(admin);
        log.warn("[seed] Created bootstrap ssadmin (username='{}', password='{}') — CHANGE ON FIRST LOGIN",
                SEED_ADMIN_USERNAME, SEED_ADMIN_PASSWORD);
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
        defaults.put("VAT_RATE", "8");                          // BR-70 VAT inclusive
        defaults.put("LOYALTY_ACCRUAL_PERCENTAGE", "1");        // BR-01
        defaults.put("LOYALTY_REDEMPTION_VALUE_PER_POINT", "100"); // BR-74
        defaults.put("LOYALTY_MAX_REDEMPTION_PERCENT", "50");   // BR-02
        defaults.put("MAX_ACTIVE_BRANCHES", "10");              // BR-54
        defaults.put("HQ_MFA_REQUIRED", "true");                // BR-83
        defaults.put("CANCEL_REFUND_ALERT_THRESHOLD", "10");    // BR-94 / BR-79

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
}
