package com.khoga.inventory.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;

import java.util.List;

/** UC-34 physical count submission. */
public record StockAuditRequest(@NotEmpty @Valid List<StockAuditLine> items) {
}
