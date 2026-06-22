package com.khoga.config;

import com.khoga.common.model.Store;
import com.khoga.common.model.SystemConfig;
import com.khoga.common.repository.SystemConfigRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;

/**
 * Reads/writes runtime configuration held in {@code SystemConfig} rows. Global values (scope
 * {@code GLOBAL}) are seeded by {@link DataSeeder}; branch overrides (scope {@code BRANCH}) are
 * written per store. Getters fall back to a caller-supplied default when a key is missing or
 * unparseable, so the app keeps working before/without seeding.
 */
@Service
public class SystemConfigService {

    public static final String GLOBAL_SCOPE = "GLOBAL";
    public static final String BRANCH_SCOPE = "BRANCH";

    private final SystemConfigRepository repository;

    public SystemConfigService(SystemConfigRepository repository) {
        this.repository = repository;
    }

    public String getGlobal(String key, String defaultValue) {
        return repository.findFirstByConfigKeyAndScope(key, GLOBAL_SCOPE)
                .map(SystemConfig::getConfigValue)
                .orElse(defaultValue);
    }

    public int getGlobalInt(String key, int defaultValue) {
        try {
            return Integer.parseInt(getGlobal(key, Integer.toString(defaultValue)));
        } catch (NumberFormatException ex) {
            return defaultValue;
        }
    }

    public boolean getGlobalBoolean(String key, boolean defaultValue) {
        return Boolean.parseBoolean(getGlobal(key, Boolean.toString(defaultValue)));
    }

    public BigDecimal getGlobalDecimal(String key, BigDecimal defaultValue) {
        try {
            return new BigDecimal(getGlobal(key, defaultValue.toPlainString()));
        } catch (NumberFormatException ex) {
            return defaultValue;
        }
    }

    /** Upsert a branch-scoped override (UC-42 / BR-47/48). */
    @Transactional
    public void setBranchConfig(Store store, String key, String value, String updatedBy) {
        SystemConfig cfg = repository
                .findFirstByConfigKeyAndScopeAndStoreId(key, BRANCH_SCOPE, store.getId())
                .orElseGet(() -> {
                    SystemConfig created = new SystemConfig();
                    created.setConfigKey(key);
                    created.setScope(BRANCH_SCOPE);
                    created.setStore(store);
                    return created;
                });
        cfg.setConfigValue(value);
        cfg.setUpdatedBy(updatedBy);
        repository.save(cfg);
    }
}
