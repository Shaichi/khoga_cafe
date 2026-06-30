package com.khoga.scheduler;

import com.khoga.auth.UserActivityTracker;
import com.khoga.common.model.User;
import com.khoga.common.repository.UserRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;

/**
 * Handles idle timeout auto-logout.
 * Job 1: Flushes in-memory activity timestamps to the database every 1 minute.
 * Job 2: Sweeps the database every 5 minutes and invalidates sessions for users idle for > 30 minutes.
 */
@Slf4j
@Component
public class SessionTimeoutScheduler {

    private final UserActivityTracker userActivityTracker;
    private final UserRepository userRepository;

    public SessionTimeoutScheduler(UserActivityTracker userActivityTracker, UserRepository userRepository) {
        this.userActivityTracker = userActivityTracker;
        this.userRepository = userRepository;
    }

    /**
     * Batch-updates lastActiveAt in the database to avoid writing on every request.
     */
    @Scheduled(fixedRate = 60_000L)
    @Transactional
    public void flushActivityToDatabase() {
        Map<UUID, LocalDateTime> activeUsers = userActivityTracker.getAndClearActiveUsers();
        if (activeUsers.isEmpty()) {
            return;
        }

        int updated = 0;
        for (Map.Entry<UUID, LocalDateTime> entry : activeUsers.entrySet()) {
            User user = userRepository.findById(entry.getKey()).orElse(null);
            if (user != null) {
                user.setLastActiveAt(entry.getValue());
                userRepository.save(user);
                updated++;
            }
        }
        if (updated > 0) {
            log.debug("[scheduler] SessionTimeout — flushed {} user activity timestamps", updated);
        }
    }

    /**
     * Finds users whose lastActiveAt is older than 30 minutes and bumps their tokenVersion
     * (which invalidates all their current JWTs via BR-18).
     */
    @Scheduled(fixedRate = 300_000L)
    @Transactional
    public void sweepIdleSessions() {
        LocalDateTime threshold = LocalDateTime.now().minusMinutes(30);
        
        // Find users who have logged in (lastActiveAt != null) and haven't been active in 30+ mins
        // Note: For a production app, we might write a native query, but iterating is fine for this scale.
        // Or we could write a custom @Query in UserRepository. Let's do it in Java for simplicity.
        
        var idleUsers = userRepository.findAll().stream()
                .filter(u -> Boolean.TRUE.equals(u.getIsActive()))
                .filter(u -> u.getLastActiveAt() != null && u.getLastActiveAt().isBefore(threshold))
                .toList();

        for (User user : idleUsers) {
            int currentTv = user.getTokenVersion() != null ? user.getTokenVersion() : 0;
            user.setTokenVersion(currentTv + 1);
            user.setLastActiveAt(null); // Clear it so we don't keep bumping them
            userRepository.save(user);
            log.info("[scheduler] SessionTimeout — user {} idle > 30m; bumped token version to log them out", user.getId());
        }
    }
}
