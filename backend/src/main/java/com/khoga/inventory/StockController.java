package com.khoga.inventory;

import com.khoga.auth.SecurityUtil;
import com.khoga.common.dto.ApiResponse;
import com.khoga.common.dto.PageResponse;
import com.khoga.common.model.enums.TransactionType;
import com.khoga.inventory.dto.CreateStockItemRequest;
import com.khoga.inventory.dto.ExportStockRequest;
import com.khoga.inventory.dto.ImportStockRequest;
import com.khoga.inventory.dto.StockAuditRequest;
import com.khoga.inventory.dto.StockAuditResultLine;
import com.khoga.inventory.dto.StockItemResponse;
import com.khoga.inventory.dto.StockTransactionResponse;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.List;

/** Branch stock management (UC-31/32/33/34/61). Store Manager scope only (BR-59). */
@RestController
@RequestMapping("/api/v1/stock")
@PreAuthorize("hasRole('STORE_MANAGER')")
public class StockController {

    private final StockService stockService;

    public StockController(StockService stockService) {
        this.stockService = stockService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<StockItemResponse>>> list(
            @RequestParam(required = false) Boolean lowStock,
            @RequestParam(required = false) String search,
            @PageableDefault(size = 20) Pageable pageable) {
        Page<StockItemResponse> page = stockService.list(lowStock, search, SecurityUtil.currentUserId(), pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.of(page)));
    }

    @PostMapping("/items")
    public ResponseEntity<ApiResponse<StockItemResponse>> createItem(
            @Valid @RequestBody CreateStockItemRequest req) {
        StockItemResponse created = stockService.createStockItem(req, SecurityUtil.currentUserId());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(created, "Đã thêm nguyên liệu vào kho chi nhánh"));
    }

    @PostMapping("/import")
    public ResponseEntity<ApiResponse<StockTransactionResponse>> importStock(
            @Valid @RequestBody ImportStockRequest req) {
        StockTransactionResponse tx = stockService.importStock(req, SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(tx, "Nhập kho thành công"));
    }

    @PostMapping("/export")
    public ResponseEntity<ApiResponse<StockTransactionResponse>> exportStock(
            @Valid @RequestBody ExportStockRequest req) {
        StockTransactionResponse tx = stockService.exportStock(req, SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(tx, "Xuất kho thành công"));
    }

    @PostMapping("/audit")
    public ResponseEntity<ApiResponse<List<StockAuditResultLine>>> audit(
            @Valid @RequestBody StockAuditRequest req) {
        List<StockAuditResultLine> result = stockService.auditStock(req, SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(result, "Kiểm kê hoàn tất"));
    }

    @GetMapping("/transactions")
    public ResponseEntity<ApiResponse<PageResponse<StockTransactionResponse>>> history(
            @RequestParam(required = false) TransactionType type,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime to,
            @PageableDefault(size = 20) Pageable pageable) {
        Page<StockTransactionResponse> page =
                stockService.history(type, from, to, SecurityUtil.currentUserId(), pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.of(page)));
    }
}
