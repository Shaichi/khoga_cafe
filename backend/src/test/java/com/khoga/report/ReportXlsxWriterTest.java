package com.khoga.report;

import com.khoga.report.dto.BestSellerRow;
import com.khoga.report.dto.BranchRevenueRow;
import com.khoga.report.dto.CashierAnomalyRow;
import com.khoga.report.dto.HqConsolidatedReport;
import com.khoga.report.dto.PaymentBreakdown;
import com.khoga.report.dto.StoreRevenueReport;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellType;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayInputStream;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** P4 — the xlsx writer produces a valid, openable workbook carrying the expected (UTF-8) data. */
class ReportXlsxWriterTest {

    private final ReportXlsxWriter writer = new ReportXlsxWriter();

    @Test
    void hqConsolidated_isValidXlsxWithData() throws Exception {
        HqConsolidatedReport r = new HqConsolidatedReport(
                LocalDate.of(2026, 5, 1), LocalDate.of(2026, 5, 31),
                new BigDecimal("1000000"), 120L, new BigDecimal("8333.33"), new BigDecimal("2.5"),
                List.of(new BranchRevenueRow(UUID.randomUUID(), "Chi nhánh Quận 1", new BigDecimal("600000"), 70L)),
                List.of(new BestSellerRow(UUID.randomUUID(), "Cà phê sữa", 200L)));

        byte[] bytes = writer.hqConsolidated(r);

        assertZip(bytes);
        List<String> texts = strings(bytes);
        assertTrue(texts.contains("Chi nhánh Quận 1"), texts.toString());   // Vietnamese survives round-trip
        assertTrue(texts.contains("Branch"));
        assertTrue(texts.contains("Cà phê sữa"));
        assertTrue(numericCellExists(bytes, "600000"), "revenue must be a numeric cell");
    }

    @Test
    void storeRevenue_isValidXlsx() throws Exception {
        StoreRevenueReport r = new StoreRevenueReport(
                LocalDate.of(2026, 5, 1), LocalDate.of(2026, 5, 31), UUID.randomUUID(),
                new BigDecimal("500000"), 60L, BigDecimal.ZERO,
                new PaymentBreakdown(new BigDecimal("300000"), new BigDecimal("150000"), new BigDecimal("50000")));

        byte[] bytes = writer.storeRevenue(r);

        assertZip(bytes);
        assertTrue(strings(bytes).contains("Total Collected"));
    }

    @Test
    void anomaly_isValidXlsxWithFlag() throws Exception {
        byte[] bytes = writer.anomaly(List.of(new CashierAnomalyRow(
                UUID.randomUUID(), "Trần Văn B", 50L, 10L, new BigDecimal("20"), 3L, new BigDecimal("6"),
                2L, 1L, true)), new BigDecimal("15"));

        assertZip(bytes);
        List<String> texts = strings(bytes);
        assertTrue(texts.contains("Trần Văn B"));
        assertTrue(texts.contains("FLAGGED"));
    }

    @Test
    void anomaly_emptyRows_stillValid() throws Exception {
        byte[] bytes = writer.anomaly(List.of(), new BigDecimal("15"));
        assertZip(bytes);
        assertTrue(strings(bytes).contains("Cashier"));   // header still present
    }

    private static void assertZip(byte[] bytes) {
        assertTrue(bytes.length > 0);
        assertEquals('P', (char) bytes[0]);
        assertEquals('K', (char) bytes[1]);   // .xlsx is an OOXML ZIP (PK header)
    }

    private static List<String> strings(byte[] bytes) throws Exception {
        List<String> out = new ArrayList<>();
        try (Workbook wb = new XSSFWorkbook(new ByteArrayInputStream(bytes))) {
            for (Sheet s : wb) {
                for (Row row : s) {
                    for (Cell c : row) {
                        if (c.getCellType() == CellType.STRING) {
                            out.add(c.getStringCellValue());
                        }
                    }
                }
            }
        }
        return out;
    }

    private static boolean numericCellExists(byte[] bytes, String numericText) throws Exception {
        double target = Double.parseDouble(numericText);
        try (Workbook wb = new XSSFWorkbook(new ByteArrayInputStream(bytes))) {
            for (Sheet s : wb) {
                for (Row row : s) {
                    for (Cell c : row) {
                        if (c.getCellType() == CellType.NUMERIC && c.getNumericCellValue() == target) {
                            return true;
                        }
                    }
                }
            }
        }
        return false;
    }
}
