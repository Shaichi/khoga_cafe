package com.khoga.report;

import com.khoga.report.dto.BestSellerRow;
import com.khoga.report.dto.BranchRevenueRow;
import com.khoga.report.dto.CashierAnomalyRow;
import com.khoga.report.dto.HqConsolidatedReport;
import com.khoga.report.dto.StoreRevenueReport;
import com.lowagie.text.Document;
import com.lowagie.text.DocumentException;
import com.lowagie.text.Font;
import com.lowagie.text.FontFactory;
import com.lowagie.text.PageSize;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.Rectangle;
import com.lowagie.text.pdf.BaseFont;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import org.springframework.stereotype.Component;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.util.List;

/**
 * PDF renderer for the exportable reports (UC-29/41/82), mirroring {@link ReportCsvWriter}'s layout.
 *
 * <p>Vietnamese names and the em-dash in titles need a Unicode font: the OS font directories are
 * registered once and the first available Unicode TrueType family is used with Identity-H encoding
 * (embedded). If none is found we fall back to Helvetica — valid PDF bytes, but non-ASCII glyphs may
 * not render. xlsx has no such constraint; prefer it when fidelity of Vietnamese text matters most.
 */
@Component
public class ReportPdfWriter {

    private static final boolean FONTS_REGISTERED = registerFonts();
    private static final List<String> UNICODE_FAMILIES =
            List.of("Arial", "Tahoma", "Segoe UI", "DejaVu Sans", "Liberation Sans", "Noto Sans");

    public byte[] hqConsolidated(HqConsolidatedReport r) {
        return render(PageSize.A4, doc -> {
            title(doc, "Khoga — Consolidated Revenue (" + r.from() + " to " + r.to() + ")");
            kv(doc, "Total Revenue", r.totalRevenue());
            kv(doc, "Total Orders", r.totalOrders());
            kv(doc, "Avg Transaction", r.avgTransactionValue());
            kv(doc, "Cancellation Rate %", r.cancellationRate());

            PdfPTable branches = table(new float[]{3, 2, 1}, "Branch", "Revenue", "Orders");
            for (BranchRevenueRow b : r.branches()) {
                addCell(branches, b.storeName());
                addCell(branches, b.revenue());
                addCell(branches, b.orders());
            }
            doc.add(branches);

            PdfPTable sellers = table(new float[]{3, 1}, "Best Seller", "Units Sold");
            for (BestSellerRow b : r.bestSellers()) {
                addCell(sellers, b.name());
                addCell(sellers, b.quantitySold());
            }
            doc.add(sellers);
        });
    }

    public byte[] storeRevenue(StoreRevenueReport r) {
        return render(PageSize.A4, doc -> {
            title(doc, "Khoga — Store Revenue (" + r.from() + " to " + r.to() + ")");
            kv(doc, "Net Revenue", r.netRevenue());
            kv(doc, "Completed Orders", r.completedOrders());
            kv(doc, "Discrepancy Total", r.discrepancyTotal());

            PdfPTable tenders = table(new float[]{2, 2}, "Tender", "Amount");
            addCell(tenders, "Cash");
            addCell(tenders, r.payments().cash());
            addCell(tenders, "Card");
            addCell(tenders, r.payments().card());
            addCell(tenders, "VietQR");
            addCell(tenders, r.payments().vietqr());
            addCell(tenders, "Total Collected");
            addCell(tenders, r.payments().total());
            doc.add(tenders);
        });
    }

    public byte[] anomaly(List<CashierAnomalyRow> rows, BigDecimal threshold) {
        return render(PageSize.A4.rotate(), doc -> {   // 9 columns — landscape
            title(doc, "Khoga — Cashier Anomaly (threshold " + threshold + "%)");
            PdfPTable t = table(new float[]{3, 1, 1, 1, 1, 1, 1, 1, 1},
                    "Cashier", "Orders", "Cancels", "Cancel %", "Refunds", "Refund %", "Vouchers", "Comps", "Flag");
            for (CashierAnomalyRow c : rows) {
                addCell(t, c.cashierName());
                addCell(t, c.orders());
                addCell(t, c.cancellations());
                addCell(t, c.cancelRate());
                addCell(t, c.refunds());
                addCell(t, c.refundRate());
                addCell(t, c.vouchers());
                addCell(t, c.comps());
                addCell(t, c.flagged() ? "FLAGGED" : "");
            }
            doc.add(t);
        });
    }

    // ----- helpers -----

    private interface Body {
        void build(Document doc) throws DocumentException;
    }

    private byte[] render(Rectangle pageSize, Body body) {
        try (ByteArrayOutputStream baos = new ByteArrayOutputStream()) {
            Document doc = new Document(pageSize, 36, 36, 36, 36);
            PdfWriter.getInstance(doc, baos);
            doc.open();
            body.build(doc);
            doc.close();
            return baos.toByteArray();
        } catch (DocumentException | IOException e) {
            throw new IllegalStateException("Không thể tạo PDF báo cáo", e);
        }
    }

    private static void title(Document doc, String text) throws DocumentException {
        Paragraph p = new Paragraph(text, font(14, Font.BOLD));
        p.setSpacingAfter(10);
        doc.add(p);
    }

    private static void kv(Document doc, String key, Object value) throws DocumentException {
        doc.add(new Paragraph(key + ": " + str(value), font(10, Font.NORMAL)));
    }

    private static PdfPTable table(float[] widths, String... headers) {
        PdfPTable t = new PdfPTable(widths);
        t.setWidthPercentage(100);
        t.setSpacingBefore(10);
        Font headerFont = font(10, Font.BOLD);
        for (String h : headers) {
            PdfPCell c = new PdfPCell(new Phrase(h, headerFont));
            c.setGrayFill(0.9f);
            t.addCell(c);
        }
        return t;
    }

    private static void addCell(PdfPTable t, Object value) {
        t.addCell(new PdfPCell(new Phrase(str(value), font(9, Font.NORMAL))));
    }

    private static String str(Object value) {
        return value == null ? "" : value.toString();
    }

    private static boolean registerFonts() {
        try {
            FontFactory.registerDirectories();
        } catch (Exception ignored) {
            // best effort — fall back to built-in Helvetica below
        }
        return true;
    }

    /** First available Unicode family (embedded, Identity-H) so Vietnamese renders; else Helvetica. */
    private static Font font(float size, int style) {
        for (String family : UNICODE_FAMILIES) {
            if (!FontFactory.isRegistered(family)) {
                continue;
            }
            try {
                Font f = FontFactory.getFont(family, BaseFont.IDENTITY_H, BaseFont.EMBEDDED, size, style);
                if (f.getBaseFont() != null) {
                    return f;
                }
            } catch (RuntimeException ex) {
                // OpenPDF throws (unchecked ExceptionConverter) for an unembeddable / .ttc /
                // license-restricted family — skip it and try the next, then fall back to Helvetica.
            }
        }
        return FontFactory.getFont(FontFactory.HELVETICA, size, style);
    }
}
