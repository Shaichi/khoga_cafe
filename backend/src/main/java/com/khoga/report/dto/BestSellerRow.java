package com.khoga.report.dto;

import java.util.UUID;

/** A best-selling menu item by units sold over the reporting period (UC-28). */
public record BestSellerRow(UUID menuItemId, String name, long quantitySold) {
}
