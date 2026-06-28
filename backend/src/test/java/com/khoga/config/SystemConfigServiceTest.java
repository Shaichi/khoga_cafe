package com.khoga.config;

import com.khoga.common.exception.AppException;
import com.khoga.common.model.SystemConfig;
import com.khoga.common.repository.SystemConfigRepository;
import com.khoga.config.dto.SystemConfigResponse;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Unit tests for the central (GLOBAL-scope) config read/update used by screen 24.
 * Update is intentionally update-only: an unknown key is rejected so typos in the
 * settings UI can't create junk rows (the seeded key set is the source of truth).
 */
@ExtendWith(MockitoExtension.class)
class SystemConfigServiceTest {

    @Mock private SystemConfigRepository repository;

    private SystemConfigService service() {
        return new SystemConfigService(repository);
    }

    private SystemConfig global(String key, String value) {
        SystemConfig c = new SystemConfig();
        c.setConfigKey(key);
        c.setConfigValue(value);
        c.setScope("GLOBAL");
        return c;
    }

    @Test
    void listGlobal_mapsGlobalConfigsToResponses() {
        when(repository.findByScopeOrderByConfigKey("GLOBAL"))
                .thenReturn(List.of(global("MAX_ACTIVE_BRANCHES", "5"), global("VAT_RATE", "10")));

        List<SystemConfigResponse> result = service().listGlobal();

        assertEquals(2, result.size());
        assertEquals("MAX_ACTIVE_BRANCHES", result.get(0).key());
        assertEquals("5", result.get(0).value());
        assertEquals("VAT_RATE", result.get(1).key());
    }

    @Test
    void setGlobal_existingKey_updatesValueAndActor() {
        SystemConfig existing = global("VAT_RATE", "10");
        when(repository.findFirstByConfigKeyAndScope("VAT_RATE", "GLOBAL")).thenReturn(Optional.of(existing));
        when(repository.save(any(SystemConfig.class))).thenAnswer(inv -> inv.getArgument(0));

        SystemConfigResponse res = service().setGlobal("VAT_RATE", "12", "actor-1");

        assertEquals("12", existing.getConfigValue());
        assertEquals("actor-1", existing.getUpdatedBy());
        assertEquals("12", res.value());
        verify(repository).save(existing);
    }

    @Test
    void setGlobal_unknownKey_throwsAndDoesNotSave() {
        when(repository.findFirstByConfigKeyAndScope("NOPE", "GLOBAL")).thenReturn(Optional.empty());

        assertThrows(AppException.class, () -> service().setGlobal("NOPE", "x", "actor-1"));
        verify(repository, never()).save(any());
    }
}
