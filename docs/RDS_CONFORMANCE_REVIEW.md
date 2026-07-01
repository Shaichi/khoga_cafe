# Đối chiếu Code ↔ RDS / Sequence Diagram — Ghi chú Review

> **Ngày:** 2026-07-01 · **Phạm vi:** toàn bộ 11 subsystem đã build vs `docs/rds_sections/*` (class diagram + mermaid `sequenceDiagram`).
> **Cách làm:** 11 sub-agent chạy song song, mỗi agent đối chiếu 1 subsystem — so từng bước data-flow trong sequence diagram với code thực tế, chỉ report **sai lệch luồng dữ liệu / thiếu bước / sai business-rule** (bỏ qua khác biệt tên COMET↔Spring, style, việc đã defer có ghi rõ).
> **Trạng thái:** đây là review **lượt 1 (tự động)** — cần xác nhận từng finding trước khi sửa. Con số file:line theo thời điểm review.

## Tổng quan

| # | Subsystem | RDS | HIGH | MED | LOW | Kết luận |
|---|-----------|-----|:----:|:---:|:---:|----------|
| 1 | Auth / Security | 04 | 1 | 1 | 2 | Luồng login/OTP/profile khớp; **thiếu khóa tài khoản khi sai MFA (BR-17)** |
| 2 | User Management | 05 | 2 | 2 | 1 | **Thiếu check unique email/phone**; sequence EMP-id không bền |
| 3 | Catalog / Menu | 06 | 2 | 2 | 1 | **Thiếu size variant + availability 2 mức tại list** |
| 4 | Voucher | 07 | 0 | 1 | 3 | Checkout khớp; lệch từ vựng trạng thái + audit thiếu old/new |
| 5 | Customer / Loyalty | 08 | 0 | 1 | 2 | Khớp tốt; cap redemption clamp âm thầm thay vì báo lỗi |
| 6 | Inventory | 09 | 0 | 1 | 2 | Trừ kho khớp BR-07/89; **thiếu row-lock chống race** |
| 7 | POS Transaction | 10 | 0 | 3 | 2 | Pipeline khớp; **callback VietQR trùng bị xử lý sai** |
| 8 | Order Management | 11 | 0 | 2 | 2 | State machine khớp; cancel có side-effect lệch RDS |
| 9 | Staff Management | 12 | 1 | 2 | 2 | **Không khóa PIN sau N lần sai (BR-93)**; UC-80 thiếu PDF |
| 10 | Config / Branch | 14 | 0 | 2 | 2 | Guard khớp; cascade deactivate thiếu hủy token + báo NV |
| 11 | Reports & BI | 13 | 1 | 2 | 1 | **COGS report tính sai (theo catalog, không theo đơn đã bán)** |
| | **Tổng** | | **7** | **19** | **20** | 46 finding |

**Đánh giá chung:** phần lõi (checkout pipeline BR-70, trừ kho recipe, state-machine order, loyalty earn, reconciliation ca, guard RBAC/scope) **bám sát sequence diagram**. Sai lệch tập trung ở: (a) **chống brute-force** (MFA & PIN lockout), (b) **tính toàn vẹn dữ liệu** (unique key, COGS, sequence id), (c) **độ đầy đủ audit** (old/new value + ActionType ngữ nghĩa), (d) **feature còn thiếu vs RDS** (size variant, availability list, HQ xem report chi nhánh).

---

## 1. Auth / Security (RDS §3.1)

- **[HIGH] Sai MFA 3 lần không khóa tài khoản (BR-17).** Diagram UC-01: `incrementMfaFailures()` → `opt mfaFailures>=3` → `lockAccount() [BR-17]`. Code `AuthService.loginMfa` + `OtpStore.verify` chỉ khóa *thử-thách OTP tạm* (`Result.LOCKED`), không đụng `User.failedAttempts`/`lockExpiryAt`. → Kẻ tấn công gọi lại `/login` là reset, đoán OTP không giới hạn.
- **[MED] Logout không ghi thời điểm (BR-13).** Diagram: `recordLogoutTime(userId)`. Code `AuthService.logout` là no-op; `User` không có `lastLogoutAt`, không audit.
- **[LOW] Kiểm tra active/lock *trước* password** (diagram kiểm sau) → lộ trạng thái tài khoản khi sai mật khẩu (enumeration nhẹ). *Judgment call — an toàn hơn về DoS, nhưng lệch flow.*
- **[LOW] Login thành công không ghi audit** (chỉ set `lastLoginAt`).

## 2. User Management (RDS §3.2)

- **[HIGH] Không check unique email khi tạo user.** Diagram: `checkEmailUnique(email)`; RDS "email và phone phải duy nhất". `UserService.create` bỏ qua (repo có `findByEmail` nhưng không dùng).
- **[HIGH] Không check unique phone khi tạo user.** Diagram `checkPhoneUnique(phone)`; repo còn không có `existsByPhone`.
- **[MED] EMP-id/username sinh từ `count()+1`** (`UserService.create:78`) — không monotonic, xóa user là trùng số cũ (BR-57 "sequential").
- **[MED] Guard BR-82 khi update chỉ chặn đổi `role`,** chưa chặn đổi permissions (active-status đã tách sang endpoint riêng — OK).
- **[LOW] Audit `oldValueJson` luôn null** ở create/update/deactivate; UC-83 không đọc được before/after.

## 3. Catalog / Menu (RDS §3.3)

- **[HIGH] Chưa hề có size variant (S/M/L qua `parentItemId`).** Diagram UC-18 có nguyên block `opt size variants … createVariantItem(parentItemId, sizeName, sku, price)`; `sku/sizeName/parentItemId` không bao giờ được set.
- **[HIGH] UC-15 list bỏ qua store context / availability 2 mức.** Diagram: `listMenuItems(storeId)` → `findStatusFor(storeId)` → `availability = isActive AND branch.isAvailable` ("Out of Stock" BR-25). `MenuItemService.list` không nhận `storeId`, không đọc `BranchMenuStatus`, response không có cờ availability; `findByIsDeletedFalse` cũng không lọc `isActive` → món inactive toàn chuỗi vẫn hiện.
- **[MED] Topping không phải global/multi-item** — UC-71 `submitTopping(dto, menuItemIds[])`; code chỉ map topping cho đúng 1 item theo path variable, không tái dùng topping global (BR-29).
- **[LOW] `abbreviation` không phiên âm bỏ dấu như ví dụ BR-26** ("Cà phê đá"→"cfd"); code ra "cpd".

## 4. Voucher (RDS §3.4)

- **[MED] Update không nạp/truyền old record vào audit.** Diagram threads `oldRecord + savedVoucher`; `VoucherService` truyền `null` + chỉ `{id}` → không diff được (BR-68).
- **[LOW] Trạng thái deactivate = `INACTIVE`** thay vì fold vào `EXPIRED` (statechart 3-state SCHEDULED/ACTIVE/EXPIRED).
- **[LOW] Hết lượt dùng bị ép `EXPIRED`** (`VoucherStatusEngine:25`), RDS nói vẫn `ACTIVE` (chỉ chặn redemption).
- **[LOW] Thiếu field `description` (≤250 ký tự)** trong entity/DTO.
- *Khớp:* min-order, per-customer limit, cap BR-42, clamp subtotal BR-50, persist usage count.

## 5. Customer / Loyalty (RDS §3.5)

- **[MED] Cap đổi điểm (BR-02) clamp âm thầm thay vì báo lỗi.** Diagram `validateSufficientPoints(...)` là cổng validate; code (`CheckoutService.validateRedeem`) chỉ check balance + bội số 100, còn `DiscountStackingEngine` *clamp* điểm quá cap → cashier không nhận lỗi, điểm dư "biến mất".
- **[LOW] Không có `LoyaltyPointCalculator.validateSufficientPoints`** — logic balance + cap bị tách rời 2 class.
- **[LOW] Audit điều chỉnh điểm dùng `ActionType.UPDATE`** (không có `POINT_ADJUSTMENT`) → report không lọc riêng được.
- *Khớp:* consent PDPA bắt buộc, phone unique, earn = floor(net×%/100) trên Net Total Payable, trừ điểm khi finalize, job hết hạn 12 tháng, lý do điều chỉnh bắt buộc + role gate.

## 6. Inventory (RDS §3.6)

- **[MED] Thiếu pessimistic lock (`findByIdForUpdate`).** Diagram UC-32/34/62 yêu cầu khóa dòng; code dùng `findById`/`findByStoreIdAndRawMaterialId` thường → 2 lần PREPARING đồng thời hoặc import/audit song song có thể mất update (read-modify-write race).
- **[LOW] Dòng `PHANTOM_USAGE` có before==after** (`RecipeDeductionEngine:96`) → snapshot nhìn như zero-delta, khó audit.
- **[LOW] MSG07 real-time lúc bán chỉ log**, không email/badge (email chỉ ở scheduler đêm). Chấp nhận theo BR-89 nhưng lệch trigger diagram.
- *Khớp:* trừ kho tại PENDING→PREPARING (không tại checkout), base+topping recipe, cho phép âm + PHANTOM_USAGE, note bắt buộc khi lệch, BR-63/64 raw material.

## 7. POS Transaction (RDS §3.7)

- **[MED] Verify chữ ký webhook VietQR nằm ở controller,** không qua `VietQrClient` (thiếu `verifyWebhookSignature`/`processCallback` — client chỉ có 1/3 operation theo thiết kế).
- **[MED] Không lưu `transactionRef` lên Order khi PAID.** Diagram `updatePaymentStatus(PAID, transactionRef)`; code chỉ log reference.
- **[MED] Callback VietQR trùng lặp bị xử lý như refund.** `awaiting = UNPAID && PENDING`; callback thứ 2 trên đơn đã PAID rơi vào nhánh else → `flagForRefund + alertStoreManager` (cảnh báo giả). Thiếu idempotency thật (nhận diện `transactionRef` đã áp → no-op).
- **[LOW] Auto-close truyền `closingCash=null`** → discrepancy=0 âm thầm (không cảnh báo BR-04) — theo thiết kế nhưng cần biết.
- *Khớp:* guard 1 ca OPEN/register, pipeline gross→voucher→loyalty→PENDING/UNPAID→finalize, +earned/−redeemed, usage++, audit, in receipt/label, tính tiền thừa, Z-report expected = opening + cash PAID − refunds.

## 8. Order Management (RDS §3.8)

- **[MED] UC-55 cancel có side-effect RDS cấm.** RDS §3.8.2: "PENDING→CANCELLED chỉ log… **không có stock/loyalty rollback**". Code khi `paymentStatus==PAID` gọi `reversePoints + restoreVoucherUsage` và set `REFUNDED`. *Lưu ý: đây là lựa chọn có chủ đích ghi trong IMPLEMENTATION_PLAN (UC-55) — **RDS và plan mâu thuẫn**, cần chốt bản nào đúng.*
- **[MED] Auto-abandon key theo `updatedAt`** (`findByStatusAndUpdatedAtBefore`) thay vì "thời gian ở trạng thái READY" — bất kỳ write sau đó reset đồng hồ.
- **[LOW] Force-close-tại-đóng-ca không check SM auth + không audit** (diagram: `forceCloseAtShiftClose() [SM authorises]`); `abandonStaleReadyOrders` cũng không ghi audit.
- **[LOW] Refund verify PIN của *bất kỳ* SM** trong store, không phải SM cụ thể (`smId`).
- *Khớp:* REFUND/COMP_REMAKE, trừ kho tại PREPARING, in tem tại READY, guard chuyển trạng thái `ALLOWED`.

## 9. Staff Management (RDS §3.9)

- **[HIGH] Sai PIN không tăng đếm / không khóa (BR-93).** Diagram `incrementPinFailedAttempts(userId)` + khóa `pinLockedUntil` sau N lần. `AttendanceService.resolveByPin` throw ngay khi sai; `pinFailedAttempts` không bao giờ được ghi, `pinLockedUntil` luôn null → đoán PIN vô hạn, nhánh "MSG02/03 số lần còn lại" không thể chạy.
- **[MED] Gán ca cross-branch không có AuditLog riêng.** Diagram `logCrossBranchAssignment(...)`; code nhét `"crossBranch":true` vào 1 row CREATE chung + `log.info` (BR-90).
- **[MED] UC-80 export thiếu PDF** (`AttendanceService` non-CSV → `err.065`).
- **[LOW] Check-in lấy `.findFirst()` lịch trong ngày** không sắp xếp → nhiều ca/ngày thì `scheduledStart` sai.
- **[LOW] Early-leave/OT không có trong enum `AttendanceStatus`** (chỉ PRESENT/LATE/ABSENT) — chỉ là field phút.
- *Khớp:* pairing check-in/out 1 row, BR-36 past-guard, BR-37 delete-notify, branch-scope, overlap+rest+daily/weekly, soft budget override, BR-72 purge ảnh.

## 10. Config / Branch (RDS §3.11)

- **[MED] UPDATE branch không ghi old/new value** (`BranchService:111` truyền `null,null`) — mất change-history (BR-80).
- **[MED] Cascade deactivate thiếu hủy token (BR-18) + báo NV (BR-37).** Code set `isActive=false` + xóa lịch tương lai nhưng không bump tokenVersion → NV chi nhánh vẫn giữ JWT hợp lệ tới khi hết hạn; không thông báo NV bị xóa ca.
- **[LOW] Update config global không ghi old value vào audit** (chỉ `{event,key}`).
- **[LOW] ActionType dùng `UPDATE` chung** cho deactivate/config thay vì `DEACTIVATE`/`CONFIG_UPDATE`.
- *Khớp:* cap BR-54, guard open-shift + non-terminal-order BR-55, scope SM own-branch BR-47/48.

## 11. Reports & BI (RDS §3.10)

- **[HIGH] COGS report tính theo catalog, không theo đơn đã bán.** RDS §3.10.3: `fetchCompletedOrders(storeId, range)` → `Σ(qty×stdCost)` trên đơn hoàn tất trong kỳ, `margin% = (revenue − cogs)/revenue`. Code `CogsReportService.margins()` bỏ qua order hoàn toàn — liệt kê mọi MenuItem/topping và tính `price − unitCost`; không có revenue/cogs/margin% theo kỳ, `from/to` không dùng cho margin. → Report sai về bản chất.
- **[MED] HQ consolidated thiếu date-granularity (daily/weekly/monthly).** RDS §3.10.2 yêu cầu; endpoint chỉ nhận `from/to/branchId`, không có time-series.
- **[MED] Store sales report (UC-40/41) HQ không xem được.** `@PreAuthorize("hasRole('STORE_MANAGER')")` + `requireOwnBranch`, không nhận `storeId` → ceoviewer/businessadmin không kéo được report 1 chi nhánh (trái BR-44 HQ-xem-tất-cả).
- **[LOW] Loyalty movement lọc theo branch nhưng điểm là chain-wide** → khi có branch filter, đẳng thức Opening+Issued−Redeemed−Expired=Closing không cân.
- *Khớp:* Z-report ngày, anomaly theo cashier, access-review, price-history, scope BR-44 cho revenue.

---

## Ghi chú kỹ thuật khi sửa

- **Thêm giá trị enum** (`ActionType`, `AttendanceStatus`, `VoucherStatus`) **vướng gotcha** `@Enumerated(STRING)` + `ddl-auto=update`: constraint CHECK cũ không tự alter → INSERT giá trị mới fail trên DB dev cũ. Phải drop CHECK constraint trước (xem CLAUDE.md).
- **Thêm cột không-null** (vd `User.lastLogoutAt`, `Order.transactionRef`) phải để **nullable** cho các dòng đã tồn tại.
- Nhiều finding "audit thiếu old/new" là **cùng 1 pattern** (mapper audit chưa nhận before-snapshot) → nên sửa 1 lần ở `AuditLogService` + call-site, không rải rác.
