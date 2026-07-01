package com.khoga.auth;

import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Tracks the last activity time for authenticated users in memory.
 * This avoids hitting the database on every single HTTP request.
 * A scheduled task flushes these timestamps to the database periodically.
 */
@Component
public class UserActivityTracker {

    private Map<UUID, LocalDateTime> activeUsers = new ConcurrentHashMap<>();

    public void recordActivity(UUID userId) {
        if (userId != null) {
            activeUsers.put(userId, LocalDateTime.now());
        }
    }

    public synchronized Map<UUID, LocalDateTime> getAndClearActiveUsers() {
        Map<UUID, LocalDateTime> currentBatch = activeUsers;
        activeUsers = new ConcurrentHashMap<>();
        return currentBatch;
    }
}
