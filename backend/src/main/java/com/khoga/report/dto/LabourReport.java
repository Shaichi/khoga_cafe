package com.khoga.report.dto;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * UC-79 labour-hours vs revenue report. Per-branch rows plus a chain-total row (HQ, all branches);
 * a Store Manager sees only their own branch and no chain total.
 */
public record LabourReport(
        LocalDate from,
        LocalDate to,
        UUID branchId,
        List<LabourRow> branches,
        LabourRow chainTotal) {
}
