package com.khoga.report.dto;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/** UC-76 COGS / margin & ingredient-shrinkage report. {@code storeId} null = chain-wide. */
public record CogsReport(
        LocalDate from,
        LocalDate to,
        UUID storeId,
        List<MarginRow> margins,
        List<ShrinkageRow> shrinkage) {
}
