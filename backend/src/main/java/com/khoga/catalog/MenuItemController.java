package com.khoga.catalog;

import com.khoga.auth.SecurityUtil;
import com.khoga.catalog.dto.AvailabilityRequest;
import com.khoga.catalog.dto.CreateMenuItemRequest;
import com.khoga.catalog.dto.MenuItemDetailResponse;
import com.khoga.catalog.dto.MenuItemResponse;
import com.khoga.catalog.dto.MenuItemStatusRequest;
import com.khoga.catalog.dto.ToppingRequest;
import com.khoga.catalog.dto.ToppingResponse;
import com.khoga.catalog.dto.UpdateMenuItemRequest;
import com.khoga.common.dto.ApiResponse;
import com.khoga.common.dto.PageResponse;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * Menu, recipe, topping and availability endpoints (UC-15/18/19/68/71/72).
 * Reads are open to any
 * authenticated staff; businessadmin manages the catalog (RDS §3.3);
 * availability toggle also
 * allows a store manager (BR-25).
 */
@RestController
@RequestMapping("/api/v1/menu-items")
public class MenuItemController {

    private final MenuItemService menuItemService;

    public MenuItemController(MenuItemService menuItemService) {
        this.menuItemService = menuItemService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<MenuItemResponse>>> list(
            @RequestParam(required = false) UUID storeId,
            @RequestParam(required = false) UUID categoryId,
            @RequestParam(required = false) String search,
            @PageableDefault(size = 20) Pageable pageable) {
        Page<MenuItemResponse> page = menuItemService.list(storeId, categoryId, search, pageable);
        return ResponseEntity.ok(ApiResponse.success(PageResponse.of(page)));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<MenuItemDetailResponse>> get(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.success(menuItemService.get(id)));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('BUSINESSADMIN','SSADMIN')")
    public ResponseEntity<ApiResponse<MenuItemDetailResponse>> create(
            @Valid @RequestBody CreateMenuItemRequest request) {
        MenuItemDetailResponse created = menuItemService.create(request, SecurityUtil.currentUserId());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(created, "Tạo món thành công"));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('BUSINESSADMIN','SSADMIN')")
    public ResponseEntity<ApiResponse<MenuItemDetailResponse>> update(
            @PathVariable UUID id, @Valid @RequestBody UpdateMenuItemRequest request) {
        MenuItemDetailResponse updated = menuItemService.update(id, request, SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(updated, "Cập nhật món thành công"));
    }

    @PutMapping("/{id}/status")
    @PreAuthorize("hasAnyRole('BUSINESSADMIN','SSADMIN')")
    public ResponseEntity<ApiResponse<MenuItemDetailResponse>> setStatus(
            @PathVariable UUID id, @Valid @RequestBody MenuItemStatusRequest request) {
        MenuItemDetailResponse updated = menuItemService.setActive(
                id, Boolean.TRUE.equals(request.active()), SecurityUtil.currentUserId());
        String message = request.active() ? "Đã tiếp tục bán món" : "Đã tạm ngưng bán món";
        return ResponseEntity.ok(ApiResponse.success(updated, message));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('BUSINESSADMIN','SSADMIN')")
    public ResponseEntity<ApiResponse<Void>> delete(@PathVariable UUID id) {
        menuItemService.softDelete(id, SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(null, "Đã xóa món (ẩn khỏi danh mục)"));
    }

    @PutMapping("/{id}/availability")
    @PreAuthorize("hasAnyRole('BUSINESSADMIN','SSADMIN','STORE_MANAGER')")
    public ResponseEntity<ApiResponse<Void>> setAvailability(
            @PathVariable UUID id, @Valid @RequestBody AvailabilityRequest request) {
        menuItemService.toggleAvailability(id, request, SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(null, "Cập nhật tình trạng món tại chi nhánh"));
    }

    @GetMapping("/toppings/all")
    public ResponseEntity<ApiResponse<List<ToppingResponse>>> listAllToppings() {
        return ResponseEntity.ok(ApiResponse.success(menuItemService.listAllToppings()));
    }

    @GetMapping("/{id}/toppings")
    public ResponseEntity<ApiResponse<List<ToppingResponse>>> listToppings(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.success(menuItemService.listToppings(id)));
    }

    @PostMapping("/{id}/toppings")
    @PreAuthorize("hasAnyRole('BUSINESSADMIN','SSADMIN')")
    public ResponseEntity<ApiResponse<ToppingResponse>> addTopping(
            @PathVariable UUID id, @Valid @RequestBody ToppingRequest request) {
        ToppingResponse created = menuItemService.addTopping(id, request, SecurityUtil.currentUserId());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(created, "Thêm topping thành công"));
    }

    @PutMapping("/{id}/toppings/{toppingId}")
    @PreAuthorize("hasAnyRole('BUSINESSADMIN','SSADMIN')")
    public ResponseEntity<ApiResponse<ToppingResponse>> updateTopping(
            @PathVariable UUID id, @PathVariable UUID toppingId, @Valid @RequestBody ToppingRequest request) {
        ToppingResponse updated = menuItemService.updateTopping(toppingId, request, SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(updated, "Cập nhật topping thành công"));
    }

    @PostMapping("/{id}/toppings/{toppingId}/link")
    @PreAuthorize("hasAnyRole('BUSINESSADMIN','SSADMIN')")
    public ResponseEntity<ApiResponse<Void>> linkTopping(
            @PathVariable UUID id, @PathVariable UUID toppingId) {
        menuItemService.linkTopping(id, toppingId, SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(null, "Đã gắn topping vào món"));
    }

    @DeleteMapping("/{id}/toppings/{toppingId}/link")
    @PreAuthorize("hasAnyRole('BUSINESSADMIN','SSADMIN')")
    public ResponseEntity<ApiResponse<Void>> unlinkTopping(
            @PathVariable UUID id, @PathVariable UUID toppingId) {
        menuItemService.unlinkTopping(id, toppingId, SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(null, "Đã bỏ topping khỏi món"));
    }

    @DeleteMapping("/{id}/toppings/{toppingId}")
    @PreAuthorize("hasAnyRole('BUSINESSADMIN','SSADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteTopping(
            @PathVariable UUID id, @PathVariable UUID toppingId) {
        menuItemService.deactivateTopping(toppingId, SecurityUtil.currentUserId());
        return ResponseEntity.ok(ApiResponse.success(null, "Đã ngừng sử dụng topping"));
    }
}
