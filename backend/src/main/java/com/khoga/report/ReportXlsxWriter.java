package com.khoga.report;

import com.khoga.report.dto.BestSellerRow;
import com.khoga.report.dto.BranchRevenueRow;
import com.khoga.report.dto.CashierAnomalyRow;
import com.khoga.report.dto.HqConsolidatedReport;
import com.khoga.report.dto.StoreRevenueReport;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Component;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.util.List;

/**
 * Excel (.xlsx) renderer for the exportable reports (UC-29/41/82). Mirrors the column/row layout of
 * {@link ReportCsvWriter} so all formats stay consistent; numbers are written as real numeric cells
 * (not text) so they remain summable in a spreadsheet. UTF-8 is native to xlsx — no font handling.
 */
@Component
public class ReportXlsxWriter {

    private static final int TEXT_WIDTH = 28 * 256;   // ~28 chars (units: 1/256 of a char)
    private static final int NUM_WIDTH = 16 * 256;

    public byte[] hqConsolidated(HqConsolidatedReport r) {
        try (Workbook wb = new XSSFWorkbook()) {
            Sheet s = wb.createSheet("Consolidated Revenue");
            CellStyle bold = boldStyle(wb);
            int n = 0;
            n = kv(s, n, bold, "Khoga — Consolidated Revenue", r.from() + " to " + r.to());
            n = kv(s, n, bold, "Total Revenue", r.totalRevenue());
            n = kv(s, n, bold, "Total Orders", r.totalOrders());
            n = kv(s, n, bold, "Avg Transaction", r.avgTransactionValue());
            n = kv(s, n, bold, "Cancellation Rate %", r.cancellationRate());
            n++;
            n = headerRow(s, n, bold, "Branch", "Revenue", "Orders");
            for (BranchRevenueRow b : r.branches()) {
                Row row = s.createRow(n++);
                cell(row, 0, b.storeName());
                cell(row, 1, b.revenue());
                cell(row, 2, b.orders());
            }
            n++;
            n = headerRow(s, n, bold, "Best Seller", "Units Sold");
            for (BestSellerRow b : r.bestSellers()) {
                Row row = s.createRow(n++);
                cell(row, 0, b.name());
                cell(row, 1, b.quantitySold());
            }
            widths(s, TEXT_WIDTH, NUM_WIDTH, NUM_WIDTH);
            return bytes(wb);
        } catch (IOException e) {
            throw new IllegalStateException("Không thể tạo Excel báo cáo", e);
        }
    }

    public byte[] storeRevenue(StoreRevenueReport r) {
        try (Workbook wb = new XSSFWorkbook()) {
            Sheet s = wb.createSheet("Store Revenue");
            CellStyle bold = boldStyle(wb);
            int n = 0;
            n = kv(s, n, bold, "Khoga — Store Revenue", r.from() + " to " + r.to());
            n = kv(s, n, bold, "Net Revenue", r.netRevenue());
            n = kv(s, n, bold, "Completed Orders", r.completedOrders());
            n = kv(s, n, bold, "Discrepancy Total", r.discrepancyTotal());
            n++;
            n = headerRow(s, n, bold, "Tender", "Amount");
            n = dataRow(s, n, "Cash", r.payments().cash());
            n = dataRow(s, n, "Card", r.payments().card());
            n = dataRow(s, n, "VietQR", r.payments().vietqr());
            n = dataRow(s, n, "Total Collected", r.payments().total());
            widths(s, TEXT_WIDTH, NUM_WIDTH);
            return bytes(wb);
        } catch (IOException e) {
            throw new IllegalStateException("Không thể tạo Excel báo cáo", e);
        }
    }

    public byte[] anomaly(List<CashierAnomalyRow> rows, BigDecimal threshold) {
        try (Workbook wb = new XSSFWorkbook()) {
            Sheet s = wb.createSheet("Cashier Anomaly");
            CellStyle bold = boldStyle(wb);
            int n = 0;
            n = kv(s, n, bold, "Khoga — Cashier Anomaly", "threshold " + threshold + "%");
            n++;
            n = headerRow(s, n, bold, "Cashier", "Orders", "Cancels", "Cancel %", "Refunds",
                    "Refund %", "Vouchers", "Comps", "Flag");
            for (CashierAnomalyRow c : rows) {
                Row row = s.createRow(n++);
                cell(row, 0, c.cashierName());
                cell(row, 1, c.orders());
                cell(row, 2, c.cancellations());
                cell(row, 3, c.cancelRate());
                cell(row, 4, c.refunds());
                cell(row, 5, c.refundRate());
                cell(row, 6, c.vouchers());
                cell(row, 7, c.comps());
                cell(row, 8, c.flagged() ? "FLAGGED" : "");
            }
            widths(s, TEXT_WIDTH, NUM_WIDTH, NUM_WIDTH, NUM_WIDTH, NUM_WIDTH, NUM_WIDTH, NUM_WIDTH, NUM_WIDTH, NUM_WIDTH);
            return bytes(wb);
        } catch (IOException e) {
            throw new IllegalStateException("Không thể tạo Excel báo cáo", e);
        }
    }

    // ----- helpers -----

    private static CellStyle boldStyle(Workbook wb) {
        CellStyle style = wb.createCellStyle();
        Font font = wb.createFont();
        font.setBold(true);
        style.setFont(font);
        return style;
    }

    private static int kv(Sheet s, int rownum, CellStyle bold, String label, Object value) {
        Row row = s.createRow(rownum);
        Cell l = row.createCell(0);
        l.setCellValue(label);
        l.setCellStyle(bold);
        cell(row, 1, value);
        return rownum + 1;
    }

    private static int dataRow(Sheet s, int rownum, String label, Object value) {
        Row row = s.createRow(rownum);
        cell(row, 0, label);
        cell(row, 1, value);
        return rownum + 1;
    }

    private static int headerRow(Sheet s, int rownum, CellStyle bold, String... headers) {
        Row row = s.createRow(rownum);
        for (int i = 0; i < headers.length; i++) {
            Cell c = row.createCell(i);
            c.setCellValue(headers[i]);
            c.setCellStyle(bold);
        }
        return rownum + 1;
    }

    /** Numbers (incl. BigDecimal) become numeric cells; everything else is text. {@code null} → blank. */
    private static void cell(Row row, int col, Object value) {
        Cell c = row.createCell(col);
        if (value == null) {
            c.setBlank();
        } else if (value instanceof Number num) {
            c.setCellValue(num.doubleValue());
        } else {
            c.setCellValue(value.toString());
        }
    }

    private static void widths(Sheet s, int... colWidths) {
        for (int i = 0; i < colWidths.length; i++) {
            s.setColumnWidth(i, colWidths[i]);   // fixed widths — avoids autoSizeColumn's headless AWT dependency
        }
    }

    private static byte[] bytes(Workbook wb) throws IOException {
        try (ByteArrayOutputStream baos = new ByteArrayOutputStream()) {
            wb.write(baos);
            return baos.toByteArray();
        }
    }
}
