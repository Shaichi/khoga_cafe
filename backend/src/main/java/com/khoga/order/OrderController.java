package com.khoga.order;

import com.khoga.auth.SecurityUtil;
import com.khoga.common.dto.ApiResponse;
import com.khoga.common.dto.PageResponse;
import com.khoga.common.model.enums.OrderStatus;
import com.khoga.order.dto.CancelOrderRequest;
import com.khoga.order.dto.ForceAbandonRequest;
import com.khoga.order.dto.OrderDetailResponse;
import com.khoga.order.dto.OrderSummaryResponse;
import com.khoga.order.dto.RefundRequest;
import com.khoga.order.dto.RefundResponse;
import com.khoga.order.dto.StatusUpdateResponse;
import com.khoga.order.dto.UpdateStatusRequest;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * Order management (UC-54/55/57/58/73/75). Queue + status transitions are open to barista, cashier and
 * store manager; cancel (UC-55) is cashier-driven; refund/comp (UC-75) requires a Store Manager PIN.
 * All operations are scoped to the actor's branch (BR-59).
 */
@RestController
@RequestMapping("/api/v1")
@PreAuthorize("hasAnyRole('CASHIER','BARISTA','STORE_MANAGER')")
public class OrderController {

    private final OrderService orderService;

    public OrderController(OrderService orderService) {
        this.orderService = orderService;
    }

    /** UC-57 — live barista queue (active orders, oldest first). */
    @GetMapping("/queue")
    public ResponseEntity<ApiResponse<List<OrderSummaryResponse>>> queue() {
        return ResponseEntity.ok(ApiResponse.success(orderService.getQueue(SecurityUtil.currentUserId())));
    }

    /** UC-54 — order history for the branch, optional status filter. */
    @GetMapping("/orders")
    public ResponseEntity<ApiResponse<PageResponse<OrderSummaryResponse>>> history(
            @RequestParam(required = false) OrderStatus status,
            @PageableDefault(size = 20) Pageable pageable) {
        Page<OrderSummaryResponse> page = orderService.getHistory(status, SecurityUtil.currentUserId(), pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.of(page)));
    }

    /** UC-73 — full order detail. */
    @GetMapping("/orders/{id}")
    public ResponseEntity<ApiResponse<OrderDetailResponse>> detail(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.success(orderService.getDetail(id, SecurityUtil.currentUserId())));
    }

    /** UC-58 — barista state transition (deducts stock on PENDING→PREPARING). */
    @PostMapping("/orders/{id}/status")
    public ResponseEntity<ApiResponse<StatusUpdateResponse>> updateStatus(
            @PathVariable UUID id, @Valid @RequestBody UpdateStatusRequest req) {
        StatusUpdateResponse res = orderService.updateStatus(id, req.status(), SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(res, "Đã cập nhật trạng thái đơn"));
    }

    /** UC-55 — cancel a PENDING order. */
    @PostMapping("/orders/{id}/cancel")
    public ResponseEntity<ApiResponse<OrderSummaryResponse>> cancel(
            @PathVariable UUID id, @Valid @RequestBody CancelOrderRequest req) {
        OrderSummaryResponse res = orderService.cancelOrder(id, req, SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(res, "Đã hủy đơn"));
    }

    /** UC-75 — SM-authorized refund / comp remake. */
    @PostMapping("/orders/{id}/refund")
    public ResponseEntity<ApiResponse<RefundResponse>> refund(
            @PathVariable UUID id, @Valid @RequestBody RefundRequest req) {
        RefundResponse res = orderService.refund(id, req, SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(res, "Đã xử lý hoàn tiền/làm lại"));
    }

    /** BR-88 — SM force-abandons the shift's remaining READY orders at shift close (SM PIN required). */
    @PostMapping("/shifts/{sessionId}/force-abandon-ready")
    @PreAuthorize("hasRole('STORE_MANAGER')")
    public ResponseEntity<ApiResponse<Integer>> forceAbandonReady(
            @PathVariable UUID sessionId, @Valid @RequestBody ForceAbandonRequest req) {
        int count = orderService.forceAbandonReadyOrders(sessionId, req.smApprovalPin(), SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(count, "Đã đóng các đơn READY còn tồn"));
    }
}
