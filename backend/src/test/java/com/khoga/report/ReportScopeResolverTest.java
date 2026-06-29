package com.khoga.report;

import com.khoga.common.exception.AppException;
import com.khoga.common.model.Store;
import com.khoga.common.model.User;
import com.khoga.common.model.enums.Role;
import com.khoga.common.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.when;

/** BR-44 scope: HQ chain-wide + any branch; Store Manager locked to own branch. */
@ExtendWith(MockitoExtension.class)
class ReportScopeResolverTest {

    @Mock private UserRepository userRepository;
    @InjectMocks private ReportScopeResolver resolver;

    private final UUID actorId = UUID.randomUUID();
    private final UUID ownStore = UUID.randomUUID();
    private final UUID otherStore = UUID.randomUUID();

    private User user(Role role, UUID storeId) {
        User u = new User();
        u.setId(actorId);
        u.setRole(role);
        if (storeId != null) {
            Store s = new Store();
            s.setId(storeId);
            u.setStore(s);
        }
        return u;
    }

    @Test
    void hqRole_nullFilterMeansAllBranches() {
        when(userRepository.findById(actorId)).thenReturn(Optional.of(user(Role.CEOVIEWER, null)));
        assertNull(resolver.resolveBranch(actorId, null));
    }

    @Test
    void hqRole_canTargetAnyBranch() {
        when(userRepository.findById(actorId)).thenReturn(Optional.of(user(Role.BUSINESSADMIN, null)));
        assertEquals(otherStore, resolver.resolveBranch(actorId, otherStore));
    }

    @Test
    void storeManager_isForcedToOwnBranch() {
        when(userRepository.findById(actorId)).thenReturn(Optional.of(user(Role.STORE_MANAGER, ownStore)));
        assertEquals(ownStore, resolver.resolveBranch(actorId, null));
    }

    @Test
    void storeManager_cannotReadAnotherBranch() {
        when(userRepository.findById(actorId)).thenReturn(Optional.of(user(Role.STORE_MANAGER, ownStore)));
        assertThrows(AppException.class, () -> resolver.resolveBranch(actorId, otherStore));
    }
}
