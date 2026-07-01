# Kế hoạch hoàn thành Backend (theo TDD)

> **Ngày:** 2026-07-01 · **Nguồn:** [RDS_CONFORMANCE_REVIEW.md](RDS_CONFORMANCE_REVIEW.md) (46 finding) + phần P4 còn tồn trong [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md).
> **Bộ test hiện tại:** 202 xanh (201 unit + 1 integration SQL Server).

## Quy ước TDD cho MỌI task
1. **RED** — viết test thất bại mô tả đúng hành vi RDS yêu cầu (đơn vị: Mockito; nếu chạm JPQL/schema → thêm assertion cho integration test).
2. **GREEN** — code tối thiểu để test xanh, tuân [CLAUDE.md] (ApiResponse, throw AppException, entity/repo ở `common`).
3. **REFACTOR** — dọn trùng lặp, giữ test xanh.
4. **Done** = test mới xanh + toàn bộ suite xanh (`mvnw.cmd -f backend/pom.xml -B test`).

---

## SPRINT 1 — Bảo mật & Toàn vẹn dữ liệu — ✅ **DONE 2026-07-01** (218 test xanh, gồm integration)

> Đã hoàn thành S1.1–S1.5 theo TDD. Ghi chú bổ sung khi làm:
> - **S1.1** còn sửa kèm lỗi ẩn: `login`/`loginMfa` tăng `failedAttempts` rồi `throw` trong cùng `@Transactional` → rollback làm mất increment ở production. Thêm `noRollbackFor = AppException.class` nên BR-11 (và BR-17 mới) mới thực sự tích lũy. Reset counter dời sang path đã xác thực đầy đủ (giữ đếm suốt bước MFA).
> - **S1.2** dùng `PinAttemptGuard` khóa **theo terminal/chi nhánh** (PIN-only không quy được lần sai cho 1 NV) — in-memory (ephemeral, hợp lý cho PIN pad); seed 2 config `ATTENDANCE_PIN_MAX_ATTEMPTS=5`, `ATTENDANCE_PIN_LOCK_MINUTES=15`. Per-user `pinLockedUntil` vẫn được tôn trọng.
> - **S1.4** đổi shape `CogsReport` (bỏ `MarginRow` catalog → `ItemMarginRow` theo đơn bán + tổng revenue/cogs/margin%); thêm JPQL `OrderItemRepository.soldAggregateByMenuItem` (đã pass context-boot của integration test).
> - **S1.5** dùng `nextEmployeeSequence()` (bỏ qua EMP-id đã tồn tại). *Còn tồn: chưa có unique-constraint DB cho `employeeId` → chống trùng khi đồng thời để ở S6 (integrity).*
> - **UC-55 (S5.2) đã chốt: theo RDS "chỉ log"** — sẽ sửa code ở Sprint 5.

### S1.1 — Khóa tài khoản khi sai MFA 3 lần (BR-17) · Auth

### S1.1 — Khóa tài khoản khi sai MFA 3 lần (BR-17) · Auth
- **RED** `AuthServiceTest`: sai OTP MFA 3 lần → `User.failedAttempts`/`lockExpiryAt` bị set; `/login` lại vẫn bị khóa.
- **GREEN** `loginMfa` khi OTP sai → tăng `user.failedAttempts`, đạt ngưỡng → `lockExpiryAt = now+15'` (dùng lại logic lockout của login mật khẩu).
- **Done** không thể reset lần đoán bằng cách gọi lại `/login`.

### S1.2 — Khóa PIN chấm công sau N lần sai (BR-93) · Staff
- **RED** `AttendanceServiceTest`: sai PIN N lần → `User.pinFailedAttempts` tăng, `pinLockedUntil` set; đúng PIN → reset.
- **GREEN** `resolveByPin`: khi không khớp, tăng `pinFailedAttempts` cho *ứng viên định danh được* / ghi nhận theo branch; đạt ngưỡng config → set `pinLockedUntil`. (Xử lý case PIN-only không định danh: khóa theo (branch, PIN) hoặc theo user khi resolve được — chốt cách trong task.)
- **Done** nhánh "MSG02/03 số lần còn lại" chạy được.

### S1.3 — Unique email + phone khi tạo/sửa user · User
- **RED** `UserServiceTest`: tạo user trùng email → AppException; trùng phone → AppException.
- **GREEN** thêm `existsByEmail`/`existsByPhone` vào `UserRepository`; check trong `create` + `update`.
- **Done** không tạo được 2 user trùng email/phone.

### S1.4 — COGS report tính theo đơn đã bán trong kỳ · Reports  *(finding nặng nhất)*
- **RED** `CogsReportServiceTest`: cho N đơn COMPLETED trong [from,to] → `cogs = Σ(orderItemQty × Σ(recipeQty×stdCost))`, `revenue`, `margin% = (revenue−cogs)/revenue`.
- **GREEN** thêm query `fetchCompletedOrders`/aggregation (JPQL constructor-expression ở `common`); viết lại `CogsReportService.margins()` theo đơn; mở rộng `CogsReport` DTO (revenue/cogs/margin%). Giữ `CogsCalculator.unitCost` để tái dùng.
- **Done** report phản ánh COGS thực kỳ, không phải margin catalog. *(Cần integration test validate JPQL mới.)*

### S1.5 — Sequence EMP-id / username bền (BR-57) · User
- **RED** `UserServiceTest`: tạo user, xóa/deactivate, tạo tiếp → không trùng `EMP-xxx`.
- **GREEN** thay `count()+1` bằng bộ đếm bền (bảng sequence / `max(employeeId)+1` / `@GeneratedValue` sequence riêng).
- **Done** id đơn điệu tăng, không tái sử dụng.

### (Catalog HIGH nằm ở Sprint 2 vì là feature-gap lớn)

---

## SPRINT 2 — Feature còn thiếu vs RDS — ✅ **DONE 2026-07-01** (224 test xanh, gồm integration)

> Đã hoàn thành S2.1–S2.4 theo TDD. Ghi chú bổ sung khi làm:
> - **S2.1** thêm DTO `MenuItemVariantRequest(sizeName, sku, price)` + field `variants` trong `CreateMenuItemRequest`; `MenuItemService.createVariants()` sinh mỗi variant là 1 `MenuItem` con (`parentItemId`=base.id), kế thừa name/category/description/imageUrl của base, tự sinh abbreviation riêng (name+size).
> - **S2.2** `list(storeId, categoryId, search, pageable)`: khi có `storeId` → dùng query `…IsActiveTrue…` (ẩn món inactive toàn chuỗi) + join `BranchMenuStatus.findByStoreIdAndMenuItemIdIn`; thêm cờ `available` vào `MenuItemResponse` (mặc định available nếu chưa có row branch). Không storeId → available = isActive.
> - **S2.3** `storeRevenue` đổi sang `resolveBranch` + nhận `storeId` optional, nới `@PreAuthorize` sang HQ_OR_SM; HQ không chọn branch → `err.092`. HQ consolidated thêm `granularity` (daily/weekly/monthly) → `trend` time-series; JPQL `OrderRepository.revenueByDay` dùng `year()/month()/day()` (tránh `cast`, đã pass context-boot integration), grouping theo kỳ ở Java (`IsoFields` cho weekly).
> - **S2.4** thêm `menuItemIds` vào `ToppingRequest`; `addTopping` tạo **1** `OptionTopping` rồi map tới (path item ∪ menuItemIds) — không nhân bản topping (BR-29).

### S2.1 — Size variant Menu (S/M/L qua `parentItemId`) · Catalog *(HIGH)*
- **RED** `MenuItemServiceTest`: tạo item kèm list variant → sinh N item con `parentItemId=base`, mỗi con có `sizeName`/`sku`/`price`.
- **GREEN** mở rộng `CreateMenuItemRequest` (list variant); vòng lặp tạo variant; set `sku/sizeName/parentItemId`.
- **Done** món có S/M/L với giá riêng.

### S2.2 — Availability 2 mức tại list (+`storeId`) · Catalog *(HIGH)*
- **RED** `MenuItemServiceTest`: `list(storeId,…)` → mỗi item có cờ `available = isActive AND BranchMenuStatus.isAvailable`; item inactive toàn chuỗi bị ẩn.
- **GREEN** thêm `storeId` vào `list`; join `BranchMenuStatus`; thêm cờ vào `MenuItemResponse`; lọc `isActive`.
- **Done** POS thấy đúng "Out of Stock"/ẩn theo chi nhánh (BR-25).

### S2.3 — HQ xem store-report + date-granularity · Reports
- **RED** `ReportController? / ReportScope`: ceoviewer gọi `/store-revenue?storeId=X` → OK; SM chỉ branch mình. HQ consolidated nhận `granularity=daily|weekly|monthly` → time-series.
- **GREEN** cho `/store-revenue` nhận `storeId` optional + nới `@PreAuthorize` cho HQ (dùng `ReportScopeResolver`); thêm param granularity + grouping vào HQ consolidated.
- **Done** BR-44 HQ-xem-mọi-branch đúng; dashboard có trend theo kỳ.

### S2.4 — Topping global/multi-item (BR-29) · Catalog
- **RED** `MenuItemServiceTest`: `submitTopping(dto, menuItemIds[])` map 1 topping cho nhiều item; tái dùng topping global.
- **GREEN** thêm `menuItemIds` vào `ToppingRequest`; map nhiều mapping.
- **Done** topping dùng lại được, không nhân bản.

---

## SPRINT 3 — Độ bền POS / Order / Inventory (MED) — ✅ **DONE 2026-07-01** (230 test xanh, gồm integration)

> Đã hoàn thành S3.1–S3.4 theo TDD. Ghi chú bổ sung khi làm:
> - **S3.1** thêm `Order.transactionRef` (nullable); callback awaiting → lưu ref rồi finalize; **duplicate trên đơn PAID cùng ref → no-op** (hết cảnh báo hoàn tiền giả); khác/không-awaiting → BR-85 reconciliation. Theo RDS §3.7.4 chuyển HMAC verify vào `VietQrClient.verifyWebhookSignature` (RealVietQrClient giữ secret + generateMac), `PaymentController` chỉ delegate. WIP header-based signature của bạn được commit riêng trước đó.
> - **S3.2** thêm `Order.readyAt` (set khi →READY) + query `findByStatusAndReadyAtBefore` → auto-abandon đo **thời gian ở READY** (write khác không reset đồng hồ); ghi audit mỗi lần abandon; thêm `forceAbandonReadyOrders(shift, smPin, actor)` cần SM auth + audit + endpoint `POST /shifts/{id}/force-abandon-ready`.
> - **S3.3** thêm `LoyaltyPointCalculator.validateSufficientPoints(...)` gộp balance (MSG11) + cap %/tuyệt đối (err.093) → **throw thay vì clamp âm thầm**; `CheckoutService.validateRedeem` gọi nó (build config trước, truyền discounted-subtotal). Inject `LoyaltyPointCalculator` vào CheckoutService (test dùng `@Spy` real).
> - **S3.4** thêm `@Lock(PESSIMISTIC_WRITE)` `findByIdForUpdate` + `findByStoreIdAndRawMaterialIdForUpdate`; dùng ở `StockService.loadForStore` (import/export/audit) và `RecipeDeductionEngine` (trừ kho) → read-modify-write không mất update khi song song.

### S3.1 — VietQR: idempotency + lưu transactionRef + verify trong client · POS
- **RED** `CheckoutServiceTest`: callback trùng trên đơn PAID → **no-op** (không refund-alert); PAID lưu `transactionRef`.
- **GREEN** thêm `Order.transactionRef` (nullable); nhánh "đã PAID + cùng ref → no-op"; đưa `verifyWebhookSignature` vào `VietQrClient`.
- **Done** webhook lặp không tạo cảnh báo giả; có link giao dịch để đối soát.

### S3.2 — Order: auto-abandon theo thời-gian-ở-READY + audit + SM-auth force-close
- **RED** `OrderServiceTest`: đơn READY quá `READY_ABANDON_TIMEOUT` (đo từ lúc vào READY) → ABANDONED + audit; write khác không reset đồng hồ. Force-close cần SM auth.
- **GREEN** lưu mốc `readyAt` (hoặc query theo mốc vào READY); ghi audit ở abandon/force-close; thêm SM PIN cho force-close-at-shift-close.
- **Done** abandon đúng ngữ nghĩa + có vết audit.

### S3.3 — Cap đổi điểm: báo lỗi thay vì clamp âm thầm (BR-02) · Customer/POS
- **RED** `CheckoutServiceTest`: redeem vượt cap %/tuyệt đối → AppException (không âm thầm bỏ điểm dư).
- **GREEN** thêm `LoyaltyPointCalculator.validateSufficientPoints(...)` (gộp balance+cap); `validateRedeem` gọi nó và throw khi vượt.
- **Done** cashier nhận lỗi rõ ràng; điểm trừ = điểm hiển thị.

### S3.4 — Pessimistic lock tồn kho · Inventory
- **RED** (integration hoặc mock) `StockItemRepository.findByIdForUpdate` được dùng ở import/export/audit/recipe-deduction.
- **GREEN** thêm `@Lock(PESSIMISTIC_WRITE)` query; dùng ở `StockService` + `RecipeDeductionEngine`.
- **Done** read-modify-write không mất update khi song song.

---

## SPRINT 4 — Đầy đủ Audit (MED/LOW, nhiều finding cùng pattern)

### S4.1 — Ghi old/new value cho mọi mutation (BR-80/68/81)
- **RED** test: update user/voucher/branch/config/customer → audit row có `oldValueJson` + `newValueJson` khác null, chứa field đổi.
- **GREEN** nạp snapshot before trong service; sửa 1 chỗ ở call-site/`AuditLogService` (tránh rải rác).
- **Done** UC-77/83 diff được before/after.

### S4.2 — ActionType ngữ nghĩa
- **RED** test: điều chỉnh điểm → `POINT_ADJUSTMENT`; config → `CONFIG_UPDATE`; deactivate → `DEACTIVATE`; cross-branch schedule → audit riêng.
- **GREEN** thêm giá trị `ActionType` (⚠️ **drop CHECK constraint DB dev cũ** trước — CLAUDE.md gotcha); cập nhật call-site.
- **Done** report lọc theo action được.

### S4.3 — Logout time (BR-13) + login-success audit · Auth
- **RED** `AuthServiceTest`: logout → set `lastLogoutAt` + audit; login OK → audit.
- **GREEN** thêm `User.lastLogoutAt` (nullable); ghi audit.
- **Done** có vết đăng nhập/đăng xuất.

---

## SPRINT 5 — Từ vựng & Quyết định thiết kế

### S5.1 — Voucher status: EXPIRED thay vì INACTIVE + hết-lượt vẫn ACTIVE
- **RED** `VoucherStatusEngineTest`: deactivate → EXPIRED; hết `maxTotalUses` → vẫn ACTIVE (chỉ chặn redemption).
- **GREEN** bỏ `INACTIVE`, sửa engine; (nếu bỏ enum value → drop CHECK constraint). Thêm field `description` (≤250).
- **Done** khớp statechart 3-state.

### S5.2 — CHỐT mâu thuẫn RDS↔Plan cho UC-55 cancel · Order  *(cần quyết định người dùng)*
- RDS: cancel "chỉ log, không rollback"; Plan: cancel đơn PAID → rollback + REFUNDED. **Chọn 1**, sửa bên còn lại (code hoặc RDS) rồi bổ sung test khớp.

### S5.3 — Branch deactivate: hủy token (BR-18) + báo NV (BR-37) · Branch
- **RED** `BranchServiceTest`: deactivate branch → mọi user branch bị bump `tokenVersion`; gửi notify.
- **GREEN** trong cascade `deactivate`, bump `tokenVersion` (tái dùng cơ chế BR-18 có sẵn) + gọi `EmailService`.
- **Done** NV chi nhánh bị đá phiên + được báo.

---

## SPRINT 6 — P4 còn tồn (từ IMPLEMENTATION_PLAN)

- **Integration thật**: `SmtpEmailService`, VietQR thật + verify HMAC production, `PrinterService` ESC/POS — toggle qua profile (stub giữ cho test).
- **OTP store bền** (DB/Redis) thay in-memory — đa node/sống sót restart.
- **Hiệu năng & toàn vẹn**: index cho query report/lookup; rà `@Transactional` cho checkout/refund/trừ kho (atomic); làm tròn tiền VND; timezone UTC↔branch-local.
- **Auto-logout idle ≥30'** (silent token refresh).
- **i18n**: gắn mã MSG cho ~170 literal còn lại (seam đã sẵn).
- **Test E2E + tải**: login→checkout→prepare→complete; refund/cancel; load NFR (100 TPS, 2000 đơn/ngày/branch).

---

## Thứ tự đề xuất
`S1 (bảo mật/toàn vẹn)` → `S2 (feature gap)` → `S3 (bền POS/Order)` → `S4 (audit)` → `S5 (từ vựng/quyết định)` → `S6 (hardening P4)`.
Riêng **S5.2** cần bạn chốt trước khi code.
