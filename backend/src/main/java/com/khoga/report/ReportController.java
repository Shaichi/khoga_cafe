package com.khoga.report;

import com.khoga.auth.SecurityUtil;
import com.khoga.common.dto.ApiResponse;
import com.khoga.common.dto.PageResponse;
import com.khoga.common.exception.AppException;
import com.khoga.report.dto.AnomalyReport;
import com.khoga.report.dto.AuditChangeRow;
import com.khoga.report.dto.CogsReport;
import com.khoga.report.dto.DailyZReport;
import com.khoga.report.dto.HqConsolidatedReport;
import com.khoga.report.dto.LabourReport;
import com.khoga.report.dto.LoyaltyLiabilityReport;
import com.khoga.report.dto.StoreRevenueReport;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.UUID;
import java.util.function.Supplier;

/**
 * P3 Reports & BI (read-only). UC-28/29, UC-40/41, UC-76, UC-77, UC-78, UC-79, UC-81, UC-82, UC-83.
 * Branch scope (BR-44) is enforced in the services via {@link ReportScopeResolver}; this layer adds
 * the per-endpoint role gate. HQ roles = ceoviewer/businessadmin/ssadmin.
 */
@RestController
@RequestMapping("/api/v1/reports")
public class ReportController {

    private static final String HQ = "hasAnyRole('CEOVIEWER','BUSINESSADMIN','SSADMIN')";
    private static final String HQ_OR_SM = "hasAnyRole('CEOVIEWER','BUSINESSADMIN','SSADMIN','STORE_MANAGER')";

    private final RevenueReportService revenueReportService;
    private final CogsReportService cogsReportService;
    private final ChangeHistoryService changeHistoryService;
    private final LoyaltyLiabilityService loyaltyLiabilityService;
    private final LabourEfficiencyService labourEfficiencyService;
    private final ZReportService zReportService;
    private final AnomalyDetector anomalyDetector;
    private final ReportCsvWriter csv;
    private final ReportXlsxWriter xlsx;
    private final ReportPdfWriter pdf;

    public ReportController(RevenueReportService revenueReportService,
                            CogsReportService cogsReportService,
                            ChangeHistoryService changeHistoryService,
                            LoyaltyLiabilityService loyaltyLiabilityService,
                            LabourEfficiencyService labourEfficiencyService,
                            ZReportService zReportService,
                            AnomalyDetector anomalyDetector,
                            ReportCsvWriter csv,
                            ReportXlsxWriter xlsx,
                            ReportPdfWriter pdf) {
        this.revenueReportService = revenueReportService;
        this.cogsReportService = cogsReportService;
        this.changeHistoryService = changeHistoryService;
        this.loyaltyLiabilityService = loyaltyLiabilityService;
        this.labourEfficiencyService = labourEfficiencyService;
        this.zReportService = zReportService;
        this.anomalyDetector = anomalyDetector;
        this.csv = csv;
        this.xlsx = xlsx;
        this.pdf = pdf;
    }

    // ----- UC-28/29 HQ consolidated revenue -----

    @GetMapping("/hq-consolidated")
    @PreAuthorize(HQ)
    public ResponseEntity<ApiResponse<HqConsolidatedReport>> hqConsolidated(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(required = false) UUID branchId) {
        return ResponseEntity.ok(ApiResponse.success(
                revenueReportService.hqConsolidated(from, to, branchId, SecurityUtil.currentUserId())));
    }

    @GetMapping("/hq-consolidated/export")
    @PreAuthorize(HQ)
    public ResponseEntity<byte[]> hqConsolidatedExport(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(required = false) UUID branchId,
            @RequestParam(required = false, defaultValue = "csv") String format) {
        HqConsolidatedReport r = revenueReportService.hqConsolidated(from, to, branchId, SecurityUtil.currentUserId());
        return render(format, "hq-consolidated",
                () -> csv.hqConsolidated(r), () -> xlsx.hqConsolidated(r), () -> pdf.hqConsolidated(r));
    }

    // ----- UC-40/41 store revenue -----

    @GetMapping("/store-revenue")
    @PreAuthorize("hasRole('STORE_MANAGER')")
    public ResponseEntity<ApiResponse<StoreRevenueReport>> storeRevenue(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ResponseEntity.ok(ApiResponse.success(
                revenueReportService.storeRevenue(from, to, SecurityUtil.currentUserId())));
    }

    @GetMapping("/store-revenue/export")
    @PreAuthorize("hasRole('STORE_MANAGER')")
    public ResponseEntity<byte[]> storeRevenueExport(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(required = false, defaultValue = "csv") String format) {
        StoreRevenueReport r = revenueReportService.storeRevenue(from, to, SecurityUtil.currentUserId());
        return render(format, "store-revenue",
                () -> csv.storeRevenue(r), () -> xlsx.storeRevenue(r), () -> pdf.storeRevenue(r));
    }

    // ----- UC-76 COGS / margin & shrinkage -----

    @GetMapping("/cogs")
    @PreAuthorize(HQ_OR_SM)
    public ResponseEntity<ApiResponse<CogsReport>> cogs(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(required = false) UUID branchId) {
        return ResponseEntity.ok(ApiResponse.success(
                cogsReportService.cogsReport(from, to, branchId, SecurityUtil.currentUserId())));
    }

    // ----- UC-77 price & voucher change history -----

    @GetMapping("/price-history")
    @PreAuthorize(HQ)
    public ResponseEntity<ApiResponse<PageResponse<AuditChangeRow>>> priceHistory(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(required = false, defaultValue = "ALL") String type,
            @RequestParam(required = false) UUID actorId,
            @PageableDefault(size = 20) Pageable pageable) {
        Page<AuditChangeRow> page = changeHistoryService.priceVoucherHistory(from, to, type, actorId, pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.of(page)));
    }

    // ----- UC-83 access review (account changes) -----

    @GetMapping("/access-review")
    @PreAuthorize("hasAnyRole('CEOVIEWER','SSADMIN')")
    public ResponseEntity<ApiResponse<PageResponse<AuditChangeRow>>> accessReview(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(required = false) UUID actorId,
            @PageableDefault(size = 20) Pageable pageable) {
        Page<AuditChangeRow> page = changeHistoryService.accessReview(from, to, actorId, pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.of(page)));
    }

    // ----- UC-78 loyalty liability & movement -----

    @GetMapping("/loyalty-liability")
    @PreAuthorize(HQ)
    public ResponseEntity<ApiResponse<LoyaltyLiabilityReport>> loyaltyLiability(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(required = false) UUID branchId) {
        return ResponseEntity.ok(ApiResponse.success(
                loyaltyLiabilityService.liability(from, to, branchId, SecurityUtil.currentUserId())));
    }

    // ----- UC-79 labour vs revenue -----

    @GetMapping("/labour")
    @PreAuthorize(HQ_OR_SM)
    public ResponseEntity<ApiResponse<LabourReport>> labour(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(required = false) UUID branchId) {
        return ResponseEntity.ok(ApiResponse.success(
                labourEfficiencyService.labour(from, to, branchId, SecurityUtil.currentUserId())));
    }

    // ----- UC-81 daily Z-report -----

    @GetMapping("/z-report/{date}")
    @PreAuthorize(HQ_OR_SM)
    public ResponseEntity<ApiResponse<DailyZReport>> zReport(
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam(required = false) UUID branchId) {
        return ResponseEntity.ok(ApiResponse.success(
                zReportService.dailyZReport(date, branchId, SecurityUtil.currentUserId())));
    }

    // ----- UC-82 cashier anomaly -----

    @GetMapping("/anomaly")
    @PreAuthorize(HQ_OR_SM)
    public ResponseEntity<ApiResponse<AnomalyReport>> anomaly(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(required = false) UUID branchId) {
        return ResponseEntity.ok(ApiResponse.success(
                anomalyDetector.detect(from, to, branchId, SecurityUtil.currentUserId())));
    }

    @GetMapping("/anomaly/export")
    @PreAuthorize(HQ_OR_SM)
    public ResponseEntity<byte[]> anomalyExport(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(required = false) UUID branchId,
            @RequestParam(required = false, defaultValue = "csv") String format) {
        AnomalyReport report = anomalyDetector.detect(from, to, branchId, SecurityUtil.currentUserId());
        return render(format, "cashier-anomaly",
                () -> csv.anomaly(report.cashiers(), report.thresholdPercent()),
                () -> xlsx.anomaly(report.cashiers(), report.thresholdPercent()),
                () -> pdf.anomaly(report.cashiers(), report.thresholdPercent()));
    }

    private static final String XLSX_TYPE =
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";

    /**
     * Picks the writer/content-type/extension for {@code format} (csv|xlsx|pdf, default csv) and only
     * builds the chosen one (suppliers defer generation). Unknown formats → 400 via {@link AppException}.
     */
    private ResponseEntity<byte[]> render(String format, String base,
                                          Supplier<byte[]> csvFn, Supplier<byte[]> xlsxFn, Supplier<byte[]> pdfFn) {
        return switch (format == null ? "csv" : format.toLowerCase()) {
            case "csv" -> file(csvFn.get(), base + ".csv", "text/csv");
            case "xlsx" -> file(xlsxFn.get(), base + ".xlsx", XLSX_TYPE);
            case "pdf" -> file(pdfFn.get(), base + ".pdf", "application/pdf");
            default -> throw new AppException("Định dạng xuất không hỗ trợ (chỉ csv, xlsx, pdf): " + format);
        };
    }

    private ResponseEntity<byte[]> file(byte[] body, String filename, String contentType) {
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.parseMediaType(contentType))
                .body(body);
    }
}
