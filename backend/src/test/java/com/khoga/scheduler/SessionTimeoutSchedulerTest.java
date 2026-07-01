package com.khoga.scheduler;

import com.khoga.auth.UserActivityTracker;
import com.khoga.common.model.User;
import com.khoga.common.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SessionTimeoutSchedulerTest {

    @Mock
    private UserActivityTracker userActivityTracker;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private SessionTimeoutScheduler scheduler;

    @Test
    void sweepIdleSessions_bumpsTokenVersionForIdleUsers() {
        User idleUser = new User();
        idleUser.setId(UUID.randomUUID());
        idleUser.setIsActive(true);
        idleUser.setLastActiveAt(LocalDateTime.now().minusMinutes(35));
        idleUser.setTokenVersion(1);

        // Mocking the new repository method we are about to add (RED phase)
        when(userRepository.findIdleUsers(any(LocalDateTime.class))).thenReturn(List.of(idleUser));

        scheduler.sweepIdleSessions();

        ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(captor.capture());
        
        User saved = captor.getValue();
        assertEquals(2, saved.getTokenVersion());
        assertNull(saved.getLastActiveAt());
    }
}
