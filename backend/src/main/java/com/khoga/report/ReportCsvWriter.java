package com.khoga.report;

import com.khoga.report.dto.BranchRevenueRow;
import com.khoga.report.dto.CashierAnomalyRow;
import com.khoga.report.dto.HqConsolidatedReport;
import com.khoga.report.dto.StoreRevenueReport;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;

/**
 * Hand-rolled CSV rendering for the export-flagged reports (UC-29/41/82). No external dependency —
 * mirrors the UC-80 worked-hours CSV approach. Binary Excel/PDF export is deferred to P4 (needs a
 * spreadsheet/PDF library).
 */
@Component
public class ReportCsvWriter {

    public byte[] hqConsolidated(HqConsolidatedReport r) {
        StringBuilder sb = new StringBuilder();
        sb.append("Khoga — Consolidated Revenue,").append(r.from()).append(" to ").append(r.to()).append('\n');
        sb.append("Total Revenue,").append(r.totalRevenue()).append('\n');
        sb.append("Total Orders,").append(r.totalOrders()).append('\n');
        sb.append("Avg Transaction,").append(r.avgTransactionValue()).append('\n');
        sb.append("Cancellation Rate %,").append(r.cancellationRate()).append('\n');
        sb.append('\n').append("Branch,Revenue,Orders\n");
        for (BranchRevenueRow b : r.branches()) {
            sb.append(esc(b.storeName())).append(',').append(b.revenue()).append(',').append(b.orders()).append('\n');
        }
        sb.append('\n').append("Best Seller,Units Sold\n");
        r.bestSellers().forEach(b -> sb.append(esc(b.name())).append(',').append(b.quantitySold()).append('\n'));
        return bytes(sb);
    }

    public byte[] storeRevenue(StoreRevenueReport r) {
        StringBuilder sb = new StringBuilder();
        sb.append("Khoga — Store Revenue,").append(r.from()).append(" to ").append(r.to()).append('\n');
        sb.append("Net Revenue,").append(r.netRevenue()).append('\n');
        sb.append("Completed Orders,").append(r.completedOrders()).append('\n');
        sb.append("Discrepancy Total,").append(r.discrepancyTotal()).append('\n');
        sb.append('\n').append("Tender,Amount\n");
        sb.append("Cash,").append(r.payments().cash()).append('\n');
        sb.append("Card,").append(r.payments().card()).append('\n');
        sb.append("VietQR,").append(r.payments().vietqr()).append('\n');
        sb.append("Total Collected,").append(r.payments().total()).append('\n');
        return bytes(sb);
    }

    public byte[] anomaly(java.util.List<CashierAnomalyRow> rows, BigDecimal threshold) {
        StringBuilder sb = new StringBuilder();
        sb.append("Khoga — Cashier Anomaly (threshold ").append(threshold).append("%)\n");
        sb.append("Cashier,Orders,Cancels,Cancel %,Refunds,Refund %,Vouchers,Comps,Flag\n");
        for (CashierAnomalyRow c : rows) {
            sb.append(esc(c.cashierName())).append(',').append(c.orders()).append(',').append(c.cancellations())
                    .append(',').append(c.cancelRate()).append(',').append(c.refunds()).append(',')
                    .append(c.refundRate()).append(',').append(c.vouchers()).append(',').append(c.comps())
                    .append(',').append(c.flagged() ? "FLAGGED" : "").append('\n');
        }
        return bytes(sb);
    }

    private static String esc(String v) {
        if (v == null) {
            return "";
        }
        if (v.contains(",") || v.contains("\"") || v.contains("\n")) {
            return '"' + v.replace("\"", "\"\"") + '"';
        }
        return v;
    }

    private static byte[] bytes(StringBuilder sb) {
        return sb.toString().getBytes(StandardCharsets.UTF_8);
    }
}
