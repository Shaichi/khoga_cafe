package com.khoga.branch.dto;

/**
 * Branch-scoped operational settings a store manager may tune for their own branch (UC-42).
 * Both fields are optional; only non-null values are persisted as {@code BRANCH}-scoped config.
 */
public record BranchSettingsRequest(String timezone, String printerAddress) {
}
