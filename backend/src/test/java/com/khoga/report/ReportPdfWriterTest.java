package com.khoga.report;

import com.khoga.report.dto.BestSellerRow;
import com.khoga.report.dto.BranchRevenueRow;
import com.khoga.report.dto.CashierAnomalyRow;
import com.khoga.report.dto.HqConsolidatedReport;
import com.khoga.report.dto.PaymentBreakdown;
import com.khoga.report.dto.StoreRevenueReport;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** P4 — the PDF writer produces a well-formed PDF document for each report (incl. Vietnamese data). */
class ReportPdfWriterTest {

    private final ReportPdfWriter writer = new ReportPdfWriter();

    @Test
    void hqConsolidated_isValidPdf() {
        HqConsolidatedReport r = new HqConsolidatedReport(
                LocalDate.of(2026, 5, 1), LocalDate.of(2026, 5, 31),
                new BigDecimal("1000000"), 120L, new BigDecimal("8333.33"), new BigDecimal("2.5"),
                List.of(new BranchRevenueRow(UUID.randomUUID(), "Chi nhánh Quận 1", new BigDecimal("600000"), 70L)),
                List.of(new BestSellerRow(UUID.randomUUID(), "Cà phê sữa", 200L)));

        assertPdf(writer.hqConsolidated(r));
    }

    @Test
    void storeRevenue_isValidPdf() {
        StoreRevenueReport r = new StoreRevenueReport(
                LocalDate.of(2026, 5, 1), LocalDate.of(2026, 5, 31), UUID.randomUUID(),
                new BigDecimal("500000"), 60L, BigDecimal.ZERO,
                new PaymentBreakdown(new BigDecimal("300000"), new BigDecimal("150000"), new BigDecimal("50000")));

        assertPdf(writer.storeRevenue(r));
    }

    @Test
    void anomaly_isValidPdf_withVietnameseName() {
        byte[] bytes = writer.anomaly(List.of(new CashierAnomalyRow(
                UUID.randomUUID(), "Trần Văn B", 50L, 10L, new BigDecimal("20"), 3L, new BigDecimal("6"),
                2L, 1L, true)), new BigDecimal("15"));

        assertPdf(bytes);
    }

    @Test
    void anomaly_emptyRows_stillValidPdf() {
        assertPdf(writer.anomaly(List.of(), new BigDecimal("15")));
    }

    private static void assertPdf(byte[] bytes) {
        assertTrue(bytes.length > 100, "PDF should not be trivially empty");
        assertEquals("%PDF", new String(bytes, 0, 4, StandardCharsets.US_ASCII));
    }
}
