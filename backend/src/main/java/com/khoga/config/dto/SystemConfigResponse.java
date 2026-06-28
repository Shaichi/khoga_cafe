package com.khoga.config.dto;

import java.time.LocalDateTime;

/**
 * A single chain-wide configuration entry (GLOBAL scope) for the central settings
 * screen (UC-24). {@code key} is the stable config identifier; {@code value} is the
 * stored string (callers parse per key).
 */
public record SystemConfigResponse(String key, String value, String updatedBy, LocalDateTime updatedAt) {
}
