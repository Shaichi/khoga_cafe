# Bảng đối soát tài liệu (SRS ↔ RDS ↔ Code ↔ Plan)

> Mục đích: liệt kê **từng điểm lệch** giữa SRS (`docs/sections/`), RDS (`docs/rds_sections/`), code (`backend/`) và [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md), kèm **đề xuất sửa** để bạn duyệt từng dòng.
>
> Quy ước: mỗi mục có ô **Quyết định** — đánh `OK` nếu đồng ý đề xuất, hoặc ghi cách bạn muốn.
> Định hướng nền (đã chốt): **SRS §5 appendix + §2 là nguồn chân lý**; RDS (toàn bộ ghi 2026-06-18) là bản cũ → mặc định **sửa RDS theo SRS**, trừ khi ghi rõ "code mới là chuẩn".
>
> Trạng thái: ✅ **ĐÃ THỰC THI 2026-06-27** — toàn bộ A/B/E/F đã duyệt & áp dụng.
>
> **Quyết định người dùng:** A17 = giữ 3-state · A37 = đơn giản hóa (không hoàn kho) · A40 = CSV/PDF · A46 = String "REG-01" + bắt buộc CASHIER · A58 = theo SRS (bỏ `managerUserId`) · B9 = String + `is_active` · C4 = seed ceoviewer · D5 = Z-report dùng `VAT_RATE`.
>
> **Đã làm:** Code C/D/E (CEOVIEWER + seed `ceoviewer` + config defaults theo SRS + bỏ `SystemConfig.updatedAt` + 3 unique constraint) → build unit test **xanh (exit 0)**. RDS 04–14 patch theo A1–A59 (6 sub-agent). DB-design `03` + architecture `01` + package `02` → **23 bảng**, global topping, variant, `com.khoga`, Spring Boot 4.1.0/Java 21. CLAUDE.md + IMPLEMENTATION_PLAN cập nhật.
>
> **Còn lại (làm ở pha sau):** (1) **drop CHECK-constraint `users.role`** trên DB dev cũ để seed ceoviewer chạy (xem CLAUDE.md gotcha); (2) A13 (`BranchMenuStatus.lastUpdatedBy/At`) + A44 (`User.pinFailedAttempts/pinLockedUntil`) là field thiết kế mới — thêm vào entity khi build catalog/P2.4; (3) D5 (Z-report VAT) + A46 logic "bắt buộc CASHIER" thuộc tầng service P2/P3 (chưa có code).

---

## PHẦN A — SRS ↔ RDS (mặc định: sửa RDS theo SRS)

### A.1 Auth & Security
- **A1 · Sai số BR khóa tài khoản** — SRS: BR-11 (5 sai → khóa 15'). RDS statechart ghi "BR-15" (BR-15 = mật khẩu mới ≠ cũ). → **Sửa RDS: BR-15 → BR-11.** Quyết định: ⬜
- **A2 · Mô hình khóa thiếu** — SRS: sau 15' tự mở; **SM hoặc ssadmin** mở khóa. RDS: chỉ ssadmin mở, **không có auto-expiry 15'**. → **Sửa RDS: thêm auto-expiry 15' + cho SM mở khóa nhân viên branch.** Quyết định: ⬜
- **A3 · MFA bỏ TOTP** — SRS BR-83: 2FA = email-OTP **hoặc TOTP**, 3 lần sai → khóa (BR-17). RDS: chỉ email-OTP, không có nhánh TOTP/khóa-3-lần. → **Sửa RDS: thêm nhánh TOTP + khóa 3 lần.** (Lưu ý: code P1B chỉ làm email-OTP trước; TOTP có thể để P4 — cần ghi rõ trong plan.) Quyết định: ⬜
- **A4 · UC-02 Logout không có trong RDS** — SRS: UC-02 + BR-13 (log thời điểm) + BR-60 (logout ≠ đóng ca). RDS: chỉ có method `logout(token)`, không flow. → **Sửa RDS: thêm flow UC-02 + BR-13/BR-60.** Quyết định: ⬜
- **A5 · UC-83 Access Review + hành vi ceoviewer thiếu** — SRS: UC-83 (BR-81). RDS §3.1/§3.2 không có. → **Sửa RDS: thêm UC-83.** Quyết định: ⬜
- **A6 · Self-escalation BR-82 hẹp hơn** — SRS BR-82(b): KHÔNG user nào tự đổi role/quyền/**trạng thái** mình. RDS: chỉ chặn ssadmin tự *nâng role*. → **Sửa RDS: mở rộng đúng BR-82 (mọi user, gồm cả status).** Quyết định: ⬜
- **A7 · Validate Add-User thiếu** — SRS UC-11: unique username **+ email + phone**, BR-57 (EMP-id), BR-58 (sinh username). RDS: chỉ check username unique + store tồn tại. → **Sửa RDS: bổ sung email/phone unique + BR-57/BR-58** (code đã có `UsernameGenerator`/`TemporaryPasswordGenerator`). Quyết định: ⬜
- **A8 · AuditLog schema actor/target** — SRS BR-81: log có actor + target + before/after role/status. RDS & **code** = `userId` đơn + `oldValueJson/newValueJson`. → **Đề xuất giữ schema code** (actor = `userId`, target + before/after gói trong JSON); **sửa SRS BR-81 mô tả lại cho khớp** (hoặc thêm cột `target_user_id` nếu bạn muốn tách). Quyết định: ⬜
- **A9 · SM mở khóa nhân viên** — SRS: SM được mở khóa staff branch mình (BR-11/UC-12 AT2). RDS §3.2 actor chỉ ssadmin. → **Sửa RDS: thêm SM vào nhánh unlock branch-scope.** Quyết định: ⬜

### A.2 Catalog (Menu/Category/Topping/Recipe)
- **A10 · Topping per-item vs global** — SRS BR-29: "global hoặc selective". **Code = global + bảng `MenuItemToppingMapping`.** RDS = `OptionTopping.menuItemId` FK (per-item). → **Code là chuẩn; sửa RDS: bỏ `menuItemId` khỏi OptionTopping, thêm entity mapping + quan hệ N-N.** Quyết định: ⬜
- **A11 · MenuItem biến thể size** — SRS: nhiều biến thể S/M/L + giá riêng. **Code = có `parentItemId`/`sizeName`/`sku`.** RDS = 1 giá đơn, không có biến thể. → **Code là chuẩn; sửa RDS: thêm mô hình variant.** Quyết định: ⬜
- **A12 · BR-68 audit giá** — SRS: log khi **đổi giá** (UPDATE). RDS UC-18 diagram log lúc **CREATE**. → **Sửa RDS: nói rõ log cả CREATE và PRICE_UPDATE; BR-68 gắn với đổi giá.** Quyết định: ⬜
- **A13 · BranchMenuStatus field audit** — SRS: status branch lưu thêm "ai sửa + thời điểm". RDS entity chỉ `(storeId, menuItemId, isAvailable)`. **Code BranchMenuStatus cũng chưa có 2 field này.** → **Đề xuất: thêm `lastUpdatedBy`/`lastUpdatedAt` vào entity + RDS** (hoặc bỏ yêu cầu này khỏi SRS nếu không cần). Quyết định: ⬜
- **A14 · UC-72 Delete Menu thiếu sequence RDS** — SRS §3.3.5 (soft-delete BR-28). RDS chỉ có method, không diagram. → **Sửa RDS: thêm UC-72.** Quyết định: ⬜
- **A15 · UC-15 availability 2 mức** — SRS BR-25: list hiển thị "Out of Stock" theo (active toàn chuỗi AND available tại branch); actor gồm Cashier/POS. RDS `listMenuItems()` không có tham số store. → **Sửa RDS: thêm store-context cho list view.** Quyết định: ⬜

### A.3 Voucher
- **A16 · UC-27 đụng nghĩa** — SRS: UC-27 = *View Customer History*; redeem điểm = UC-49. RDS §3.5.3: UC-27 = *Redeem Loyalty Points*. → **Sửa RDS: redeem = UC-49, UC-27 = history.** Quyết định: ⬜
- **A17 · Voucher status 3 vs 4** — SRS BR-52: 3 trạng thái tính động (SCHEDULED/ACTIVE/EXPIRED), deactivate = terminal. RDS: 4 trạng thái (DRAFT/ACTIVE/EXHAUSTED/DEACTIVATED) + cho `reactivate()`. → **Đề xuất theo SRS 3-state**; *cân nhắc* giữ "EXHAUSTED" như sub-status tính động (đã hết lượt dùng) — bạn chọn. Quyết định: ⬜
- **A18 · Reactivate voucher** — SRS BR-41: deactivate là terminal, chặn dùng ngay. RDS: cho DEACTIVATED→ACTIVE. → **Sửa RDS: bỏ reactivate (theo BR-41).** Quyết định: ⬜
- **A19 · Range % của voucher** — SRS: chỉ nói "dương". RDS: `discountValue ∈ [1..100]` cho PERCENTAGE. → **Đề xuất: nhận quy tắc [1..100] của RDS vào SRS** (đúng và chặt hơn). Quyết định: ⬜
- **A20 · Sai số BR audit voucher** — SRS: BR-68. RDS ghi "BR-81". → **Sửa RDS → BR-68.** Quyết định: ⬜
- **A21 · ID rule cap %** — SRS gắn cap % vào BR-42. RDS ghi "BR-66". → **Sửa RDS → BR-42.** Quyết định: ⬜
- **A22 · Voucher.description** — SRS có field Description (max 250). RDS entity thiếu. **Code Voucher cũng cần kiểm** (nếu thiếu thì thêm). → **Sửa RDS + thêm field nếu cần.** Quyết định: ⬜

### A.4 Customer / Loyalty
- **A23 · Manual point adjust + Reason (BR-49)** — SRS §3.8.3: businessadmin chỉnh điểm + bắt buộc lý do. RDS coordinator không có. **Code đã có `PointAdjustmentRequest`.** → **Sửa RDS: thêm thao tác adjust-with-reason.** Quyết định: ⬜
- **A24 · Cap & expiry loyalty thiếu trong RDS** — SRS: `LOYALTY_MAX_REDEMPTION_PERCENT/LIMIT` (BR-02), hết hạn 12 tháng (BR-35). RDS `validateSufficientPoints` chỉ check số dư. → **Sửa RDS: thêm cap %/tuyệt đối + expiry.** Quyết định: ⬜
- **A25 · Base tích điểm** — SRS BR-69: base = **Net Total Payable**. RDS `calculateEarned(orderTotal)` mơ hồ. → **Sửa RDS: ghi rõ base = Net Total Payable.** Quyết định: ⬜
- **A26 · birthDate khách** — Code + RDS có `birthDate`; SRS form Add/Edit không có. → **Đề xuất: code là chuẩn, thêm birthDate (optional) vào SRS.** Quyết định: ⬜

### A.5 Inventory / POS / Order (vận hành)
- **A27 · BR-85 late-callback (NGHIÊM TRỌNG)** — SRS: callback cho đơn đã hủy KHÔNG hồi sinh; đẩy hàng đợi refund + báo SM. RDS: `updatePaymentStatus(PAID)` vô điều kiện → **sẽ thành bug tiền thật nếu code theo RDS.** → **Sửa RDS: thêm guard trạng thái + reconciliation queue (BR-85).** Quyết định: ⬜
- **A28 · UC-id đụng độ POS/Order/Inventory** — SRS: UC-53 Close Shift, UC-55 Refund/Cancel, UC-73 View Order Detail, UC-61 Import/Export History. RDS xoay vòng (UC-53=VietQR, UC-55=Close Shift, UC-58=Cancel, UC-73=Auto-Abandon, UC-61=Low-Stock). → **Sửa RDS: đánh lại UC-id đúng SRS.** Quyết định: ⬜
- **A29 · READY timeout cứng** — SRS BR-88: `READY_ABANDON_TIMEOUT` (cấu hình). RDS hardcode 15'. → **Sửa RDS: tham số hóa (default 15').** Quyết định: ⬜
- **A30 · SM force-close READY→ABANDONED** — SRS BR-88 có. RDS state machine chỉ có auto-timeout. → **Sửa RDS: thêm transition force-close của SM.** Quyết định: ⬜
- **A31 · BR-04 lệch quỹ 100k** — SRS: lệch >100k → email SM. RDS đóng ca không có ngưỡng/email. → **Sửa RDS: thêm ngưỡng 100k + email/fallback.** Quyết định: ⬜
- **A32 · Auto-close ca 23:59** — RDS thêm `ShiftAutoCloseScheduler` 23:59 (khớp scheduler skeleton). SRS không nói. → **Đề xuất: nhận vào SRS, NHƯNG phải guard BR-03 (không auto-close khi còn đơn chưa terminal).** Quyết định: ⬜
- **A33 · BR-65 trừ kho topping** — SRS: trừ recipe của món **và từng topping**. RDS narrative chỉ nói "recipe". → **Sửa RDS: nói rõ trừ cả topping.** Quyết định: ⬜
- **A34 · Enum loại stock transaction** — SRS text cũ ghi `AUTO/AUDIT`; **code + RDS** = `IMPORT/EXPORT/AUDIT_ADJUSTMENT/RECIPE_DEDUCTION/PHANTOM_USAGE`. → **Code là chuẩn; sửa SRS text khớp enum code.** Quyết định: ⬜
- **A35 · RawMaterial standard_cost/status trong RDS** — SRS + **code** có `standardCost` + `isActive`. RDS entity bỏ. → **Sửa RDS: thêm lại (cần cho COGS BR-66).** Quyết định: ⬜
- **A36 · UC-74 Raw Material Master thiếu trong RDS inventory** — SRS UC-74 (BR-63/64). RDS không có. → **Sửa RDS: thêm UC-74.** Quyết định: ⬜
- **A37 · BR-07 mâu thuẫn nội bộ SRS** — Appendix BR-07: hàng đóng gói trừ kho lúc checkout & **hoàn kho khi hủy PENDING**; hàng pha chế trừ lúc PREPARING & không hoàn. Nhưng UC-55 (§3.7) ghi "stock rollbacked" chung chung, còn plan/CLAUDE rút gọn thành "KHÔNG hoàn kho". → **Cần bạn chốt:** giữ mô hình 2 loại (đóng gói vs pha chế) của BR-07, hay đơn giản hóa "chỉ trừ ở PREPARING, không hoàn"? (ảnh hưởng thiết kế Inventory P2). Quyết định: ⬜
- **A38 · BR-84 auto-confirm vs `confirmQrPaid()`** — SRS: VietQR auto-confirm khi callback (không cần xác nhận tay). RDS có method `confirmQrPaid()` gợi ý xác nhận thủ công. → **Sửa RDS: bỏ/đổi nghĩa `confirmQrPaid` thành auto.** Quyết định: ⬜

### A.6 Staff
- **A39 · UC-66 đụng nghĩa** — SRS: UC-66 = *View Branch Staff List*. RDS: UC-66 = *Attendance Check-in*. (SRS không đánh số cho check-in — đó là BR-53/BR-93.) → **Sửa RDS: UC-66 = Branch Staff List; cấp UC-id mới cho check-in (vd UC-67) hoặc giữ là BR.** Quyết định: ⬜
- **A40 · Export CSV/PDF vs Excel** — SRS UC-80: CSV/PDF. RDS: `exportExcel()`. → **Đề xuất chốt 1 chuẩn (CSV/PDF theo SRS, hoặc hỗ trợ cả 3).** Quyết định: ⬜
- **A41 · BR-36/BR-37 bị bỏ trong RDS** — SRS: không sửa lịch quá khứ (BR-36); xóa lịch + thông báo NV (BR-37). RDS không mô hình hóa. → **Sửa RDS: thêm guard quá khứ + flow xóa+notify.** Quyết định: ⬜
- **A42 · BR-53 vs BR-93 trùng** — Cả hai mô tả PIN 4 số + ảnh check-in. → **Đề xuất gộp: BR-93 là quy tắc PIN/ảnh, BR-53 là định nghĩa thao tác; sửa SRS để không chồng lấn.** Quyết định: ⬜
- **A43 · Mô hình AttendanceLog** — SRS: 1 dòng/sự kiện (CHECK_IN/CHECK_OUT). **Code = 1 dòng gộp** (`checkInAt`+`checkOutAt`+`status`). RDS = giống code. → **Đề xuất: code là chuẩn (1 dòng gộp), sửa SRS §3.9.4 + BR-77 pairing theo mô hình này.** Quyết định: ⬜
- **A44 · PIN lockout field** — SRS BR-93: PIN khóa sau N lần sai. RDS + **code User** chưa có field đếm/khóa PIN. → **Đề xuất: thêm `pinFailedAttempts`/`pinLockedUntil` vào User (khi làm P2.4).** Quyết định: ⬜
- **A45 · Ảnh: lưu URL+ngày xóa vs path+cron** — SRS: lưu URL + `photo_purge_at`. **Code = `photoUrl`** + cron `PhotoAutoDeleteScheduler` (skeleton có sẵn). → **Đề xuất: theo code (cron quét 90 ngày, không cần cột purge_at); sửa SRS/RDS cho khớp.** Quyết định: ⬜
- **A46 · posRegisterId kiểu & bắt buộc** — SRS: mã chuỗi "REG-01", **bắt buộc khi role=CASHIER**. RDS: `Integer`, optional, không điều kiện role. → **Cần chốt kiểu + quy tắc bắt buộc.** Quyết định: ⬜

### A.7 Reports / Config / Branch
- **A47 · BR-35 mang 2 nghĩa** — SRS: BR-35 = hết hạn điểm loyalty; cap chi nhánh = **BR-54**. RDS dùng "BR-35" cho cap chi nhánh (3 chỗ). → **Sửa RDS: cap chi nhánh → BR-54.** Quyết định: ⬜
- **A48 · UC-76/77/79 xoay vòng** — SRS: UC-76 COGS/Shrinkage, UC-77 Price&Voucher History, UC-79 Labour vs Revenue. RDS: §3.10.3 "UC-79 COGS", §3.10.5 "UC-76 Price History". → **Sửa RDS: đánh lại đúng SRS.** Quyết định: ⬜
- **A49 · UC-41 Export vs Z-Report Archive** — SRS: UC-41 = Export Store Reports. RDS gọi "Z-Report Archive". → **Sửa RDS: UC-41 = Export; Z-report là UC-81.** Quyết định: ⬜
- **A50 · UC-63/64 add/edit hoán nhãn RDS** — SRS: 63 View, 64 Add, 65 Update/Deactivate. RDS sequence dán nhãn lệch. → **Sửa RDS.** Quyết định: ⬜
- **A51 · Loyalty liability điểm vs VND** — SRS BR-75: báo cáo bằng **điểm**, không quy VND. RDS `estimateLiabilityValue(...VND)`. → **Sửa RDS: chính = điểm** (VND chỉ là phụ nếu muốn). Quyết định: ⬜
- **A52 · Anomaly threshold cứng** — SRS BR-79: dùng key `CANCEL_REFUND_ALERT_THRESHOLD`. RDS hardcode ">10%". → **Sửa RDS: dùng key cấu hình.** Quyết định: ⬜
- **A53 · Anomaly actor & scope** — SRS UC-82: SM (branch) + ceoviewer (chain), phạm vi void/refund/voucher/comp theo cashier. RDS: actor ssadmin/businessadmin + thêm "stock-discrepancy". → **Sửa RDS actor theo SRS;** cân nhắc tách "stock-discrepancy" thành mục riêng. Quyết định: ⬜
- **A54 · Z-report theo ngày vs theo ca** — SRS BR-78: gom **cả ngày** (mọi ca). RDS `ZReportArchiveView` theo `shiftSessionId`. → **Sửa RDS: gom theo business-day.** Quyết định: ⬜
- **A55 · UC-42 form cố định vs key/value** — SRS BR-47: SM sửa setting branch (timezone/hardware/logo) qua form; ssadmin KHÔNG sửa local. RDS: form generic `(storeId, configKey, overrideValue)` + ngầm ssadmin sở hữu config. → **Sửa RDS: form branch do SM sở hữu, đúng BR-47.** Quyết định: ⬜
- **A56 · BR-55 guard đơn chưa terminal** — SRS: chặn deactivate khi còn đơn PENDING/PREPARING/HOLD/READY. RDS chỉ check ca mở. → **Sửa RDS: thêm guard đơn.** Quyết định: ⬜
- **A57 · BR-56 cascade deactivate** — SRS: vô hiệu user + hủy token (BR-18) + xóa lịch tương lai + notify (BR-37) + giữ lịch sử read-only. RDS chỉ `setIsActive(false)`. → **Sửa RDS: thêm cascade.** Quyết định: ⬜
- **A58 · AddBranchForm.managerUserId** — RDS có field gán SM khi tạo branch; SRS UC-64 chỉ name/address/phone. → **Cần chốt: giữ field (gán SM lúc tạo) hay theo SRS.** Quyết định: ⬜
- **A59 · VietQR creds là central config** — RDS UC-30 liệt kê; SRS §3.13 không. → **Đề xuất: thêm vào SRS danh mục config.** Quyết định: ⬜

---

## PHẦN B — Code ↔ DB-design doc (`03_database_design.md`) — *bạn chọn "xem chi tiết rồi quyết"*

> Bối cảnh: doc ghi **21 bảng**, CLAUDE.md/plan ghi **22**, code thực tế **23 bảng**. `ddl-auto=update` ⇒ entity = schema.

- **B1 · Thêm bảng `SystemConfig`** vào DB-design (đang dùng khắp nơi, doc không có). → **Thêm.** Quyết định: ⬜
- **B2 · Thêm bảng `MenuItemToppingMapping`** (global topping). → **Thêm.** Quyết định: ⬜
- **B3 · `OptionTopping` bỏ `menuItemId`** trong ERD (global). → **Sửa ERD.** Quyết định: ⬜
- **B4 · `MenuItem` thêm field** `parentItemId`, `sku`, `sizeName`, `description`, `imageUrl` vào ERD. → **Thêm vào doc** (code đã có). Quyết định: ⬜
- **B5 · `User` thêm field** `employeeId`, `failedAttempts`, `lockExpiryAt`, `passwordLastChangedAt`. → **Thêm vào doc.** Quyết định: ⬜
- **B6 · `Customer` thêm field** `birthDate`, `isActive`. → **Thêm vào doc.** Quyết định: ⬜
- **B7 · `updated_at` ở mọi bảng** (từ `BaseEntity`) — ERD không vẽ. → **Bổ sung ghi chú vào doc.** Quyết định: ⬜
- **B8 · `Order.status`** (code) vs `order_status` (doc). → **Sửa tên cột trong doc → `status`.** Quyết định: ⬜
- **B9 · `RawMaterial`** — doc: `enum category` + soft-delete `is_deleted`; code: `category` kiểu **String** + `is_active` (không có `is_deleted`). → **Cần chốt:** đổi `category` thành enum? dùng `is_active` thay `is_deleted`? Quyết định: ⬜
- **B10 · `AttendanceLog` cột ảnh** — doc prose ghi `photo_path`, ERD ghi `photo_url`, code = `photo_url`/`photoUrl`. → **Sửa prose doc → `photo_url`.** Quyết định: ⬜
- **B11 · Tên bảng auto-plural sai chính tả** — code sinh `categorys`, `branchmenustatuss`, `menuitems`… (không snake_case). → **Đề xuất: chưa đổi vội** (đổi `@Table(name=...)` sẽ tạo bảng mới do `ddl-auto=update`, mất dữ liệu dev). Cân nhắc chuẩn hóa khi có Flyway (P4). Quyết định: ⬜
- **B12 · Cột `text` (description/json/reason)** map thành `NVARCHAR` mặc định. → **Đề xuất: thêm `@Lob`/`columnDefinition` nếu cần text dài; ưu tiên thấp.** Quyết định: ⬜

---

## PHẦN C — ✅ ĐÃ CHỐT: Thêm role `CEOVIEWER`

> Bạn chọn "Thêm CEOVIEWER ngay". Các thay đổi cụ thể sẽ thực hiện:
- **C1** · Thêm `CEOVIEWER` vào [Role.java](backend/src/main/java/com/khoga/common/model/enums/Role.java) → mô hình 6 role khớp SRS §2.1.
- **C2** · ⚠️ Gotcha (CLAUDE.md): DB đã tạo có CHECK-constraint enum cũ → thêm value sẽ vỡ INSERT trên DB dev đang có. Cần **drop constraint cũ** trên `dbo.users` (hoặc recreate bảng) sau khi thêm.
- **C3** · Gắn `@PreAuthorize` cho các endpoint báo cáo HQ read-only (UC-28/29/76/77/78/79/82/83) cho `CEOVIEWER` (làm khi build P3) + cập nhật RBAC.
- **C4** · (Tùy chọn) Seed sẵn 1 tài khoản `ceoviewer` demo trong `DataSeeder`. Xác nhận? Quyết định: ⬜

---

## PHẦN D — ✅ ĐÃ CHỐT: Default config theo số SRS

> Bạn chọn "Theo đúng số SRS". Sửa `DataSeeder`:
- **D1** · `VAT_RATE`: 8 → **10**.
- **D2** · `MAX_ACTIVE_BRANCHES`: 10 → **5**.
- **D3** · `CANCEL_REFUND_ALERT_THRESHOLD`: 10 → **5**.
- **D4** · Thêm seed `LOYALTY_MAX_REDEMPTION_LIMIT` = **100000** (BR-94, đang thiếu).
- **D5** · (Liên quan) Z-report công thức VAT đang hardcode `10/110` → đổi theo `VAT_RATE` để khớp khi VAT đổi. Quyết định: ⬜

---

## PHẦN E — Sửa code (toàn vẹn dữ liệu)
- **E1 · `SystemConfig.updatedAt` đè `BaseEntity.updatedAt`** ([SystemConfig.java:29](backend/src/main/java/com/khoga/common/model/SystemConfig.java#L29)) — 2 field cùng map cột `updated_at`. → **Bỏ field thừa trong SystemConfig.** Quyết định: ⬜
- **E2 · `BranchMenuStatus` thiếu unique `(store_id, menu_item_id)`** (có TODO trong code) → rủi ro nhân bản. → **Thêm `@UniqueConstraint`.** Quyết định: ⬜
- **E3 · `StockItem` thiếu unique `(store_id, raw_material_id)`** → **Thêm `@UniqueConstraint`.** Quyết định: ⬜
- **E4 · `MenuItemToppingMapping` thiếu unique `(menu_item_id, option_topping_id)`** → **Thêm `@UniqueConstraint`.** Quyết định: ⬜

---

## PHẦN F — Sửa Plan / CLAUDE.md / Architecture doc
- **F1 · Số bảng** — CLAUDE.md & plan ghi "22", RDS architecture ghi "21 entities/21 tables". → **Chốt = 23, sửa cả 3 nơi.** Quyết định: ⬜
- **F2 · Plan: thêm task "Thêm CEOVIEWER + RBAC báo cáo"** (P1B hoặc đầu P3). Quyết định: ⬜
- **F3 · Architecture doc sai stack/package** — RDS ghi `com.khoga.coffeeshop` + "Spring Boot 3.x/Java 17". → **Sửa: `com.khoga`, Spring Boot 4.1.0/Java 21.** Quyết định: ⬜
- **F4 · Tên package config** — RDS package diagram ghi `com.khoga.config_module`; code dùng `com.khoga.config`. → **Sửa RDS → `com.khoga.config`.** Quyết định: ⬜

---

## Tổng hợp số mục
- Phần A (SRS↔RDS): **59 → A1–A59** (mặc định sửa RDS theo SRS, trừ A8/A10/A11/A26/A34/A43/A45 = code chuẩn, và A17/A19/A32/A37/A40/A46/A58 = cần bạn chốt hướng).
- Phần B (Code↔DB-design): **B1–B12.**
- Phần C/D: đã chốt (chờ xác nhận C4, D5).
- Phần E (code): **E1–E4.**
- Phần F (plan/doc): **F1–F4.**
