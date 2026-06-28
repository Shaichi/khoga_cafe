package com.khoga.branch.dto;

/**
 * Current branch-scoped operational settings (UC-42), read back for the settings form (screen 33).
 * Values are null when never configured for the branch. Mirrors {@link BranchSettingsRequest}.
 */
public record BranchSettingsResponse(String timezone, String printerAddress) {
}
