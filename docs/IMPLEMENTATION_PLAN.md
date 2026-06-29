# Kế hoạch hoàn thiện Backend Khoga Coffee Shop

## Bối cảnh (Context)

Nền tảng (`com.khoga.common` = 23 entity + repository + `ApiResponse` + exception/`GlobalExceptionHandler`; `com.khoga.config` = JPA/CORS/OpenAPI/Security) đã có sẵn. Plan này ban đầu được viết khi repo *chỉ* có base framework; xem **Trạng thái hiện tại** bên dưới để biết phần đã build.

> **Trạng thái hiện tại (cập nhật 2026-06-29):** **P0** (hạ tầng + Auth MVP), **P1** (master data), **P1B** (Auth nâng cao: quên mật khẩu UC-03/04/05 + MFA HQ BR-83), **toàn bộ P2 Vận hành (2.1 Inventory / 2.2 POS / 2.3 Order / 2.4 Staff)** và **toàn bộ P3 Báo cáo & BI (UC-28/29/40/41/76/77/78/79/81/82/83)** **đã hoàn thành + có test** — checkbox tương ứng đã `[x]`. Bộ test: **202 test xanh** (201 unit + 1 integration full-context trên SQL Server). **P4** (cứng hóa) đang làm dở — đã xong: **PDPA jobs (BR-35 + BR-72)**, **session invalidation BR-18** (tokenVersion claim + filter check), **i18n MSG01–17** (MessageSource vi/en + localize error/security path), **export Excel/PDF** (POI + OpenPDF cho UC-29/41/82). Chưa làm: integration thật (SMTP/VietQR/Printer), OTP store bền (DB/Redis), hiệu năng/E2E/load. *Hoãn: OTP còn in-memory; export attendance UC-80 vẫn CSV; ~170 message literal còn lại chưa gắn mã MSG (seam đã sẵn).*

Tài liệu thiết kế (`docs/sections/` = URD, `docs/rds_sections/` = RDS) đặc tả **83 use case (UC-01→83)**, **~95 business rule (BR)**, 22 bảng và các thuật toán phức tạp (pipeline checkout BR-70, trừ kho theo recipe UC-62/BR-89, đối soát ca, COGS/shrinkage, loyalty, anomaly...).

Mục tiêu của plan này: lộ trình **chia nhỏ tới từng UC** để team build backend tới khi hoàn chỉnh, theo **thứ tự phụ thuộc** (hạ tầng → master data → vận hành → báo cáo), không bị rework.

**Quyết định đã chốt với người dùng:**
- Trình tự: **theo dependency** (P0→P3, + P1B, P4 cứng hóa).
- Phạm vi: **Backend REST API + Test**, **adapter tích hợp ngoài dạng interface + stub** (VietQR/SMTP/Printer), **seed + bootstrap + CI**. *Không* làm Thymeleaf/Flutter trong plan này (Flutter là project riêng `khoga_pos_app/`).
- Auth làm **MVP trước** (login + JWT + RBAC + khóa tài khoản + đổi mật khẩu lần đầu); **MFA/OTP/quên mật khẩu để Phase 1B** (sau khi có SMTP stub).
- Độ chi tiết: mỗi UC = 1 nhiệm vụ + checklist bước con; có tham chiếu UC/BR + tiêu chí hoàn thành.

## Cách dùng plan & quy ước (Legend)

Mỗi UC là 1 nhiệm vụ với checklist 6 bước (theo lát cắt dọc của module):
`DTO → Repository (query bổ sung) → Service/Logic (enforce BR) → Controller → Validation → Test`, kết bằng **✅ Done** (tiêu chí acceptance).

Quy ước bắt buộc (xem [CLAUDE.md](CLAUDE.md)) áp dụng cho MỌI task, không lặp lại trong từng UC:
- **Entity & repository đã có sẵn** trong `common` — KHÔNG tạo entity mới trong package feature; chỉ thêm query method vào repository `common`, và đặt controller/service/component trong package feature `com.khoga.<tên>`.
- Controller luôn trả `ApiResponse<T>`; lỗi nghiệp vụ `throw AppException` (→400) / `ResourceNotFoundException` (→404), KHÔNG try-catch thủ công.
- PK = UUID; enum lưu `EnumType.STRING`; endpoint prefix `/api/v1/`; mọi entity đã `extends BaseEntity`.
- Mỗi UC có thiết kế chi tiết trong `docs/rds_sections/`, yêu cầu trong `docs/sections/` — đọc đúng file của subsystem trước khi code.

## Tổng quan các Phase (thứ tự phụ thuộc)

| Phase | Tên | Nội dung | Phụ thuộc |
|---|---|---|---|
| **P0** | Hạ tầng & nền tảng | Security/JWT, conventions, Audit, Integration stub, Scheduler skeleton, Seed/Bootstrap, CI, **Auth MVP** | (gốc) |
| **P1** | Master data | Branch, User mgmt, Catalog, Voucher, Customer | P0 |
| **P1B** | Hoàn thiện Auth | Quên mật khẩu (UC-03/04/05), MFA OTP (BR-83) | P0 + SMTP stub |
| **P2** | Vận hành | Inventory, POS, Order, Staff | P1 |
| **P3** | Báo cáo & BI | Report (HQ/store/COGS/anomaly/loyalty/Z-report/audit) | P1 + P2 |
| **P4** | Cứng hóa | Integration thật, PDPA jobs, session invalidation, i18n, performance, E2E | P1–P3 |

---

## PHASE 0 — Hạ tầng & nền tảng

> Mục tiêu: dựng đủ "khung xương" để mọi feature phía sau chỉ việc cắm vào. Kết thúc P0 phải đăng nhập được, bảo vệ endpoint theo role, và có dữ liệu seed.

### 0.1 Cấu hình build & bảo mật nền
- [x] Thêm dependency: `spring-boot-starter-security`, thư viện JWT (`io.jsonwebtoken:jjwt` hoặc dùng `spring-boot-starter-oauth2-resource-server`), `spring-boot-starter-mail`, test deps (đã có `*-test`). *Lưu ý Boot 4.x tên starter tách (`-webmvc`).*
  - ✅ Done: `./mvnw clean package` xanh với deps mới.
- [x] `SecurityConfig` (`com.khoga.config`): `SecurityFilterChain` stateless, `BCryptPasswordEncoder` bean, bật `@EnableMethodSecurity`, mở `/api/v1/auth/**` + `/swagger-ui/**` + `/v3/api-docs/**`, còn lại `authenticated()`.
- [x] `JwtTokenProvider` (`com.khoga.auth`): tạo/parse JWT mang `userId`, `role`, `storeId`; TTL theo NFR (HQ 2h, branch 8h).
- [x] `JwtAuthenticationFilter`: đọc header `Authorization: Bearer`, set `SecurityContext`.
  - ✅ Done: gọi endpoint bảo vệ không token → 401; có token hợp lệ → qua; sai role → 403.

### 0.2 Chuẩn hóa shared (bổ sung `common`)
- [x] Bổ sung `GlobalExceptionHandler`: handler cho `MethodArgumentNotValidException` (gom lỗi field) + `AccessDeniedException` (403) + `AuthenticationException` (401), tất cả trả `ApiResponse.error`.
- [x] DTO phân trang dùng chung `PageResponse<T>` (BR-20 mặc định 20 bản ghi/trang).
- [x] Chuẩn mapper entity↔DTO (MapStruct hoặc mapper thủ công — chọn 1, ghi vào CLAUDE.md).
  - ✅ Done: lỗi validation trả JSON đúng chuẩn `ApiResponse` kèm danh sách field.

### 0.3 Audit subsystem (`com.khoga.audit`)
- [x] `AuditLogService.record(actionType, entity, oldJson, newJson, userId)` ghi `AuditLog` (append-only).
- [x] Cơ chế kích hoạt: AOP `@Around`/`@EntityListener` cho thay đổi giá menu (BR-68), voucher (BR-68), tài khoản (BR-81), áp voucher/điểm khi checkout (BR-80).
- [x] Đảm bảo bất biến: không expose update/delete `AuditLog`.
  - ✅ Done: thay đổi giá 1 menu item ghi đúng 1 dòng audit với old/new JSON.

### 0.4 Integration adapters (`com.khoga.integration`) — interface + stub
- [x] `EmailService` (interface) + `EmailServiceStub` (log ra console, dùng cho dev/test) + chỗ cho `SmtpEmailService` (P4). Toggle qua property/profile.
- [x] `VietQrClient` (interface) + `VietQrClientStub` (sinh QR giả, callback giả lập). Idempotency key = orderId (BR-84).
- [x] `PrinterService` (interface) + `PrinterServiceStub` (log receipt/label).
  - ✅ Done: service tầng trên gọi qua interface; bật stub mặc định ở profile `dev`/`test`.

### 0.5 Scheduler skeleton (`com.khoga.scheduler`)
- [x] `@EnableScheduling` + khai báo rỗng (no-op + log) cho 5 timer: `OrderTimeoutScheduler` (1 phút), `ShiftAutoCloseScheduler` (23:59), `LowStockAlertScheduler` (22:00), `PhotoAutoDeleteScheduler` (02:00), `OtpExpiryScheduler`. Logic thật điền ở phase tương ứng.
  - ✅ Done: app log đúng các nhịp timer; chưa cần logic.

### 0.6 Seed & Bootstrap
- [x] Seeder (`CommandLineRunner` hoặc `data.sql`): tạo `ssadmin` đầu tiên (BR-82, `mustChangePassword=true`), 1 `Store` mẫu.
- [x] Seed `SystemConfig` mặc định: `VAT_RATE`, `LOYALTY_ACCRUAL_PERCENTAGE`, `LOYALTY_REDEMPTION_VALUE_PER_POINT=100`, `LOYALTY_MAX_REDEMPTION_PERCENT/LIMIT`, `MAX_ACTIVE_BRANCHES`, `HQ_MFA_REQUIRED=true`, `CANCEL_REFUND_ALERT_THRESHOLD` (BR-45/54/94).
- [x] Dữ liệu mẫu dev (category/menu/raw material) để test nhanh — chỉ chạy ở profile `dev`.
  - ✅ Done: chạy lần đầu DB rỗng → đăng nhập được bằng ssadmin seed.

### 0.7 CI
- [x] GitHub Actions: `mvn -B verify` trên push/PR (JDK 21).
  - ✅ Done: pipeline xanh.

### 0.8 Auth MVP (`com.khoga.auth`) — *defer MFA/quên mật khẩu sang P1B*
- [x] **UC-01 Login** — BR-10, BR-11, BR-14
  - DTO `LoginRequest{username,password}`, `LoginResponse{token,role,mustChangePassword}`
  - Repo: `UserRepository.findByUsername`
  - Service: verify BCrypt; chặn `isActive=false` (BR-10); đếm `failedAttempts`, khóa 15' sau 5 lần sai (BR-11) qua `lockExpiryAt`; reset khi đúng; cập nhật `lastLoginAt`; phát JWT
  - Controller: `POST /api/v1/auth/login`
  - Validation: @NotBlank
  - Test: đúng → token; sai 5 lần → khóa; account inactive → 400
  - ✅ Done: đăng nhập trả JWT; lockout hoạt động đúng BR-11.
- [x] **UC-06 Buộc đổi mật khẩu lần đầu** — BR-12, BR-22, BR-14, BR-15
  - DTO `ForcePasswordChangeRequest`
  - Service: nếu `mustChangePassword=true` chỉ cho phép endpoint này; đặt mật khẩu mới (policy BR-14, khác mật khẩu cũ BR-15), set `mustChangePassword=false`, phát JWT
  - Controller: `POST /api/v1/auth/force-password-change`
  - Validation: `PasswordPolicyValidator` (≥8, hoa/thường/số/ký tự đặc biệt)
  - Test: mật khẩu yếu 400; trùng cũ 400; OK → đăng nhập bình thường
  - ✅ Done: user mới buộc đổi mật khẩu trước khi vào hệ thống.
- [x] **UC-02 Logout** — BR-13, BR-60
  - Service: ghi thời điểm logout; KHÔNG đóng shift session (BR-60). (Token stateless: blacklist nhẹ hoặc client xóa token — ghi rõ lựa chọn.)
  - Controller: `POST /api/v1/auth/logout`
  - ✅ Done: logout không ảnh hưởng ca POS đang mở.
- [x] **UC-07 Xem profile / UC-08 Cập nhật profile** — BR-19
  - DTO `ProfileResponse`, `ProfileUpdateRequest{email,phone}`
  - Service: lấy user từ token; cập nhật chỉ email/phone
  - Controller: `GET /api/v1/profile`, `PUT /api/v1/profile`
  - Test: cập nhật email/phone OK; không cho đổi role/username
  - ✅ Done: user tự xem/sửa liên hệ của mình.
- [x] **UC-09 Đổi mật khẩu (đang đăng nhập)** — BR-14, BR-15
  - DTO `ChangePasswordRequest{current,new}`
  - Service: verify mật khẩu hiện tại; áp policy; cập nhật hash + `passwordLastChangedAt`; audit
  - Controller: `POST /api/v1/auth/change-password`
  - Test: sai current 400; mật khẩu mới yếu 400; OK
  - ✅ Done: đổi mật khẩu an toàn, ghi audit.

---

## PHASE 1 — Master data

> Mục tiêu: tạo đủ dữ liệu gốc (chi nhánh, người dùng, menu/recipe, voucher, khách hàng) để Phase 2 vận hành có cái mà dùng.

### 1.1 Branch (`com.khoga.branch`) — phụ thuộc: Store, SystemConfig, User
- [x] **UC-63 Xem danh sách chi nhánh** — BR-44
  - DTO `BranchResponse`; Repo: `findAll` + filter `isActive`; Controller `GET /api/v1/branches`; phân trang; Test danh sách + lọc trạng thái. ✅ Done: liệt kê + lọc Active/Inactive.
- [x] **UC-64 Thêm chi nhánh** — BR-54
  - Service: đếm chi nhánh active < `MAX_ACTIVE_BRANCHES` (BR-54) else AppException; tạo Store; audit
  - Controller `POST /api/v1/branches`; Validation tên duy nhất, phone 10–12 số; Test vượt cap → 400. ✅ Done: chặn vượt cap.
- [x] **UC-65 Sửa/Vô hiệu hóa chi nhánh** — BR-55, BR-56
  - Service: chặn deactivate nếu còn ca OPEN hoặc order chưa terminal (BR-55); cascade: vô hiệu user của store + xóa lịch tương lai + giữ lịch sử read-only (BR-56)
  - Controller `PUT /api/v1/branches/{id}`, `POST /api/v1/branches/{id}/deactivate`; Test có ca mở → chặn. ✅ Done: cascade đúng BR-56.
- [x] **UC-42 Cấu hình chi nhánh (storemanager)** — BR-47, BR-48
  - Service: lưu override branch-scope vào `SystemConfig` (timezone, máy in IP/COM); chỉ SM của chính branch
  - Controller `PUT /api/v1/branches/{id}/settings`; Test SM branch khác → 403. ✅ Done: SM sửa được cấu hình branch mình.

### 1.2 User management (`com.khoga.user`) — phụ thuộc: User, Store, Audit, EmailService stub
- [x] **UC-10 Danh sách user** — BR-20 — `GET /api/v1/users` lọc role/search, phân trang 20. ✅ Done: phân trang + lọc.
- [x] **UC-11 Thêm user** — BR-22, BR-57, BR-58, BR-81
  - Service: kiểm tra username duy nhất; `UsernameGenerator` (BR-58), EMP id (BR-57); sinh mật khẩu tạm + BCrypt; `mustChangePassword=true`; gửi welcome email (stub); audit CREATE (BR-81)
  - Controller `POST /api/v1/users`; Test trùng username 400. ✅ Done: tạo user + email tạm + audit.
- [x] **UC-12 Sửa user** — BR-19, BR-82, BR-81
  - Service: chặn tự nâng quyền/đổi trạng thái chính mình (BR-82); cập nhật role/branch/status; audit UPDATE. Controller `PUT /api/v1/users/{id}`; Test self-escalation → 400. ✅ Done: không tự nâng quyền.
- [x] **UC-13 Chi tiết user + lịch sử** — BR-21 — `GET /api/v1/users/{id}` kèm 50 login gần nhất + audit của user. ✅ Done: hiện chi tiết + audit.
- [x] **UC-14 Vô hiệu/Kích hoạt user** — BR-23, BR-81, BR-18
  - Service: chặn vô hiệu ssadmin active cuối cùng (BR-23); set isActive; (P4: hủy token BR-18); audit. Controller `POST /api/v1/users/{id}/deactivate`; Test last-admin → 400. ✅ Done: bảo vệ admin cuối.

### 1.3 Catalog (`com.khoga.catalog`) — phụ thuộc: Category, MenuItem, OptionTopping, RawMaterial, RecipeItem, BranchMenuStatus, Audit
- [x] **UC-16/17/69/70 Category CRUD** — BR-30, BR-31, BR-62
  - Service: tạo/sửa; xóa mềm chỉ khi rỗng/đã soft-delete hết item (BR-31); khi archive thì gỡ liên kết item→uncategorized (BR-62)
  - Controller `POST/PUT/GET/DELETE /api/v1/categories`; Test xóa category còn item active → 400. ✅ Done: ràng buộc xóa đúng BR-31/62.
- [x] **UC-18 Thêm Menu item + Recipe** — BR-26, BR-29, BR-73
  - DTO gồm danh sách recipe line; Service: sinh `abbreviation` từ tên bỏ dấu + chống trùng (BR-26); validate đơn vị recipe khớp đúng `RawMaterial.unit`, không quy đổi (BR-73); barcode duy nhất
  - Controller `POST /api/v1/menu-items`; Test sai đơn vị recipe → 400. ✅ Done: tạo món + công thức hợp lệ.
- [x] **UC-19 Sửa Menu item + Recipe / toggle availability** — BR-68, BR-25, BR-30
  - Service: đổi giá → audit (BR-68); SM toggle `BranchMenuStatus.isAvailable` (mô hình 2 mức: active toàn chuỗi AND available tại branch — BR-25)
  - Controller `PUT /api/v1/menu-items/{id}`, `PUT /api/v1/menu-items/{id}/availability`; Test đổi giá ghi audit. ✅ Done: đổi giá có audit; toggle branch hoạt động.
- [x] **UC-68 Chi tiết menu / UC-15,69 List** — BR-24 — `GET` list (search autocomplete, lọc category, trạng thái) + detail (kèm recipe + topping). ✅ Done: list + detail đầy đủ.
- [x] **UC-72 Xóa Menu item** — BR-28 — xóa mềm (`isDeleted=true`) để giữ lịch sử bán. ✅ Done: không hard-delete.
- [x] **UC-71 Quản lý Topping & Option** — BR-29, BR-65 — CRUD `OptionTopping` (giá có thể = 0); topping có recipe riêng (BR-65). `POST/PUT/DELETE /api/v1/menu-items/{id}/toppings`. ✅ Done: topping + recipe riêng.
- [x] **UC-74 Quản lý Raw Material Master** — BR-63, BR-64, BR-73 — chỉ businessadmin; `code` bất biến (BR-63); đơn vị khóa khi đã có giao dịch (BR-64); xóa mềm. `POST/PUT/GET /api/v1/raw-materials`. ✅ Done: master nguyên liệu + ràng buộc bất biến.

### 1.4 Voucher (`com.khoga.voucher`) — phụ thuộc: Voucher, Audit
- [x] **UC-20 List voucher** — BR-52 — `GET /api/v1/vouchers` kèm trạng thái tính động SCHEDULED/ACTIVE/EXPIRED (`VoucherStatusEngine`). ✅ Done: hiện đúng trạng thái.
- [x] **UC-21 Thêm voucher** — BR-40, BR-42 — tạo; nếu PERCENTAGE bắt buộc `maxDiscountAmount` (cap BR-42); code duy nhất; audit (BR-68). `POST /api/v1/vouchers`. ✅ Done: tạo voucher hợp lệ + audit.
- [x] **UC-22 Sửa voucher** — BR-40 — sửa mọi field trừ `code` (bất biến); audit. `PUT /api/v1/vouchers/{id}`; Test sửa code → 400. ✅ Done: code bất biến.
- [x] **UC-23 Vô hiệu/Xóa voucher** — BR-41 — deactivate dừng mọi redemption ngay (BR-41); audit. `POST /api/v1/vouchers/{id}/deactivate`. ✅ Done: vô hiệu chặn dùng ngay.
- [x] **Service dùng lại: `VoucherValidationService.validate(code, order)`** — kiểm tra status ACTIVE, min order, usage limit/khách; trả discount (cap BR-42). *Dùng bởi POS UC-48.* ✅ Done: hàm validate tái sử dụng ở checkout.

### 1.5 Customer (`com.khoga.customer`) — phụ thuộc: Customer, Audit
- [x] **UC-24 List khách / UC-27 Lịch sử** — `GET /api/v1/customers` (search phone/tên), `GET /api/v1/customers/{id}/history`. ✅ Done: tra cứu + lịch sử.
- [x] **UC-25 Thêm khách** — BR-71 — bắt buộc consent PDPA (`consentAt`,`consentVersion`) trước khi lưu phone/email; phone duy nhất. `POST /api/v1/customers`; Test thiếu consent → 400. ✅ Done: enrol có consent.
- [x] **UC-26 Cập nhật khách / điều chỉnh điểm** — BR-49 — sửa tên/email; điều chỉnh điểm thủ công chỉ businessadmin + bắt buộc lý do; audit. `PUT /api/v1/customers/{id}`. ✅ Done: chỉnh điểm có lý do + log.
- [x] **Component dùng lại: `LoyaltyPointCalculator`** — BR-01, BR-02, BR-74, BR-69
  - `calcEarned(netTotal, accrual%)` = floor (BR-01, base = Net Total Payable BR-69); `calcRedeemValue(points)` = points×`VALUE_PER_POINT` (bội số 100, BR-74); enforce cap %/tuyệt đối (BR-02)
  - Test: tính điểm + cap chính xác. *Dùng bởi POS UC-49 và Order rollback.* ✅ Done: engine điểm chuẩn, có test số học.

---

## PHASE 1B — Hoàn thiện Auth (MFA + Quên mật khẩu)

> Không chặn P1/P2 (đã có login MVP). Chỉ cần SMTP stub (P0.4) + nơi lưu OTP. Quyết định lưu OTP: in-memory cache (`ConcurrentHashMap`/Caffeine) cho bản đầu — ghi rõ hạn chế (không sống sót restart/đa node), nâng cấp ở P4.

> **P1B DONE 2026-06-29** — OTP lưu in-memory (`com.khoga.auth.OtpStore`, ConcurrentHashMap, TTL 10' + khóa sau 3 lần sai); **không sống sót restart/đa node** → nâng cấp DB/Redis ở P4. 14 test mới (OtpStoreTest + AuthServiceTest mở rộng); tổng **175 test xanh**.

- [x] **UC-03 Quên mật khẩu** — BR-16
  - `AuthService.forgotPassword`: `findByEmail`; sinh OTP 6 số; lưu key `RESET:{userId}` + hạn 10'; gửi email (stub). `POST /api/v1/auth/forgot-password`. ✅ Done. Luôn trả 200 (chống dò email).
- [x] **UC-04 Xác thực OTP** — BR-16, BR-17
  - `AuthService.verifyOtp`: verify OTP + còn hạn; tối đa 3 lần sai → khóa (BR-17). `POST /api/v1/auth/verify-otp`. ✅ Done.
- [x] **UC-05 Đặt lại mật khẩu** — BR-14, BR-15
  - `AuthService.resetPassword`: sau OTP hợp lệ, đặt mật khẩu mới (policy `@StrongPassword` + khác cũ); consume OTP; clear lockout; audit. `POST /api/v1/auth/reset-password`. ✅ Done.
- [x] **MFA cho HQ khi login** — BR-83, BR-16, BR-17
  - `AuthService.login`: nếu `HQ_MFA_REQUIRED=true` (SystemConfig) và role ∈ {ceoviewer,businessadmin,ssadmin} (+ có email): sau verify mật khẩu, KHÔNG phát JWT — trả `LoginResponse{status=MFA_REQUIRED, mfaToken}` + gửi OTP email. `loginMfa` (`POST /api/v1/auth/login/mfa`) verify OTP → phát JWT. Branch role bỏ qua.
  - `LoginResponse` mở rộng: `{status, token, role, mustChangePassword, mfaToken}` (factory `authenticated`/`mfaRequired`); JSON backward-compatible cho FE. ✅ Done.
- [x] **`OtpExpiryScheduler`**: gọi `OtpStore.purgeExpired()` mỗi 5' (điền logic vào skeleton P0.5). ✅ Done.

---

## PHASE 2 — Vận hành (Operations)

> Phần lõi nghiệp vụ & thuật toán phức tạp nhất. Thứ tự nội bộ: Inventory → POS → Order → Staff (POS tạo order, Order chuyển PREPARING kích hoạt trừ kho của Inventory).

### 2.1 Inventory (`com.khoga.inventory`) — phụ thuộc: RawMaterial, StockItem, StockTransaction, RecipeItem; Email stub
- [ ] **UC-31 Xem tồn kho** — `GET /api/v1/stock` (lọc dưới ngưỡng); phân trang. ✅ Done: list + lọc low-stock.
- [ ] **UC-32 Nhập kho** — Service: tăng `currentQuantity`, ghi `StockTransaction(IMPORT)` kèm before/after; qty>0. `POST /api/v1/stock/import`. ✅ Done: nhập + ledger.
- [ ] **UC-33 Xuất kho** — Service: giảm tồn, ghi `EXPORT` + lý do. `POST /api/v1/stock/export`. ✅ Done: xuất + lý do.
- [ ] **UC-34 Kiểm kê** — BR-32 — Service: đặt tồn = thực đếm, ghi `AUDIT_ADJUSTMENT` + delta; bắt buộc note nếu lệch (BR-32). `POST /api/v1/stock/audit`. ✅ Done: kiểm kê bắt buộc note khi lệch.
- [ ] **UC-61 Lịch sử nhập/xuất** — `GET /api/v1/stock/transactions` lọc loại/khoảng ngày. ✅ Done: tra ledger.
- [ ] **UC-62 Tự trừ kho theo recipe (component `RecipeDeductionEngine`)** — BR-07, BR-65, BR-89
  - Logic: khi order PENDING→PREPARING, lấy `RecipeItem` của từng `OrderItem` + topping (BR-65); trừ tồn (cho phép âm — BR-89); ghi `RECIPE_DEDUCTION` (managerId=null); nếu âm → ghi `PHANTOM_USAGE` + bắn cảnh báo low-stock; KHÔNG hoàn kho khi hủy (BR-07)
  - Test: trừ đủ nguyên liệu; tồn âm tạo phantom usage. *Gọi bởi Order 2.3.* ✅ Done: trừ kho chuẩn BR-07/89.
- [ ] **`LowStockAlertScheduler` (22:00)** — BR-04/MSG07: quét mọi branch, gửi email SM khi `currentQuantity ≤ minAlertThreshold`. ✅ Done: cảnh báo tồn thấp hằng đêm.
- [ ] **Cơ sở COGS** — BR-66: hàm `unitCost(menuItem/topping)=Σ(recipeQty×standardCost)`. *Dùng bởi Report 3.x.* ✅ Done: hàm COGS chuẩn standard-cost.

### 2.2 POS (`com.khoga.pos`) — phụ thuộc: Catalog, Voucher, Customer, ShiftSession, Order; VietQR/Printer stub
- [ ] **UC-44 Mở ca** — BR-33 — tạo `ShiftSession(OPEN)`, `startingCash≥0`; 1 ca OPEN/register. `POST /api/v1/shifts/open`. ✅ Done: mở ca, chặn cash âm.
- [ ] **UC-45/46/47 Giỏ hàng** — thêm/sửa item + topping, tìm món (SKU/tên). Có thể giữ cart server-side hoặc client gửi nguyên khi submit (ghi rõ lựa chọn). ✅ Done: dựng giỏ + tìm món <100ms (NFR).
- [ ] **UC-50 Tra cứu thành viên** — `GET /api/v1/customers?phone=` gắn vào giỏ. ✅ Done: gắn khách vào đơn.
- [ ] **UC-48 Áp voucher** — BR-80 — gọi `VoucherValidationService` (1.4); ghi audit áp voucher (BR-80). `POST /api/v1/cart/apply-voucher`. ✅ Done: áp voucher + audit.
- [ ] **UC-49 Đổi điểm loyalty** — BR-02, BR-74, BR-80 — gọi `LoyaltyPointCalculator` (1.5); ghi audit (BR-80). `POST /api/v1/cart/apply-loyalty`. ✅ Done: đổi điểm + cap + audit.
- [ ] **Component `DiscountStackingEngine`** — BR-70, BR-42, BR-50, BR-69 (TRỌNG TÂM)
  - Trình tự cứng BR-70: (1) Gross subtotal → (2) trừ voucher (cap BR-42) → (3) trừ điểm (cap %/tuyệt đối) → (4) tách VAT inclusive `tax=final×rate/(100+rate)` → (5) Net Total Payable; cap Net≥0 (BR-50); accrual tính trên Net (BR-69)
  - Test số học từng bước + cap; snapshot tham số config tại thời điểm tạo đơn (BR-46). ✅ Done: pipeline khớp BR-70 có test bao phủ.
- [ ] **UC-51 Thanh toán** — BR-84, BR-85
  - CASH: nhập tiền nhận → `paymentStatus=PAID`, cộng điểm (LoyaltyCalculator), in receipt/label (stub), trả tiền thừa
  - VIETQR: `VietQrClient.generateQr(orderId,...)` idempotency=orderId (BR-84); webhook `POST /api/v1/payments/vietqr/callback` verify chữ ký → PAID; callback cho đơn đã hủy → KHÔNG hồi sinh, đẩy hàng đợi refund (BR-85)
  - Tạo `Order(PENDING)` + `OrderItem`/`OrderItemTopping`; Test idempotency + late callback. ✅ Done: thanh toán 3 phương thức; VietQR idempotent.
- [ ] **UC-52 Xuất hóa đơn** — in receipt + cup label qua `PrinterService` stub. ✅ Done: phát sinh receipt/label.
- [ ] **UC-53 Đóng ca + đối soát (component `ShiftReconciliation`)** — BR-03, BR-04
  - Chặn đóng nếu còn order chưa terminal (BR-03); `expected=opening+ΣcashPaid−refunds`; `discrepancy=closing−expected`; lệch >100k → email SM (BR-04); sinh Z-report. `POST /api/v1/shifts/close`. ✅ Done: đối soát + cảnh báo lệch quỹ.
- [ ] **`ShiftAutoCloseScheduler` (23:59)** — BR-88: tự đóng ca OPEN quá ngày. ✅ Done: auto-close ca quên đóng.

### 2.3 Order (`com.khoga.order`) — phụ thuộc: Order, OrderItem, OrderCancellation, OrderRefund; Inventory (2.1), Customer, Voucher, Printer
- [x] **UC-57 Hàng đợi barista / UC-58 Cập nhật trạng thái** — state machine PENDING→PREPARING→(HOLD)→READY→COMPLETED/ABANDONED
  - PENDING→PREPARING gọi `RecipeDeductionEngine` (2.1) ngay; `GET /api/v1/queue`, `POST /api/v1/orders/{id}/status`. ✅ Done: state machine `OrderService.ALLOWED` enforce; trừ kho 1 lần tại PENDING→PREPARING (HOLD→PREPARING không trừ lại); phantom-usage trả về `stockWarnings`.
- [x] **UC-59 In tem / UC-60 Báo sự cố** — in cup label khi READY; HOLD khi báo sự cố. ✅ Done: `printLabel` tại →READY; PREPARING→HOLD (báo sự cố) và HOLD→PREPARING (xử lý xong) trong state machine.
- [x] **UC-54 Lịch sử đơn / UC-73 Chi tiết đơn** — `GET /api/v1/orders`, `GET /api/v1/orders/{id}` (scope theo branch). ✅ Done: history phân trang + lọc status; detail kèm line + topping; `loadForStore` chặn cross-branch (BR-59).
- [x] **UC-55 Hủy đơn (PENDING)** — BR-05, BR-08, BR-51
  - Guard chỉ PENDING (BR-05); ghi `OrderCancellation` bất biến (BR-51); rollback voucher (khôi phục limit) + loyalty (trừ điểm đã cộng, hoàn điểm đã dùng) (BR-08). `POST /api/v1/orders/{id}/cancel`. ✅ Done: chỉ rollback khi đơn đã PAID → đặt `REFUNDED` để loại khỏi doanh thu.
- [x] **UC-75 Refund/Comp (sau PENDING, SM duyệt)** — BR-67, BR-09
  - Yêu cầu PIN SM; ghi `OrderRefund`; REFUND tiền mặt trừ quỹ ca đang mở (BR-09 — gắn `shiftSession`, `ShiftService` cộng dồn khi đóng ca), card/VietQR qua gateway; đảo điểm tích/hoàn điểm đã dùng; COMP_REMAKE tạo đơn clone PENDING 0đ vào lại queue (trừ kho lại khi PREPARING). `POST /api/v1/orders/{id}/refund`. ✅ Done: SM auth qua `attendancePin`; cash-refund tác động quỹ ca.
- [x] **`OrderTimeoutScheduler` (1 phút)** — BR-88: READY quá 15' → ABANDONED (không hoàn kho). ✅ Done: `OrderService.abandonStaleReadyOrders` (cutoff = `READY_ABANDON_TIMEOUT` config, mặc định 15').

### 2.4 Staff (`com.khoga.staff`) — phụ thuộc: User, StaffSchedule, AttendanceLog; Email/Photo storage
- [x] **UC-35 Xem lịch / UC-66 Danh sách NV** — BR-59 — SM chỉ xem branch mình; `GET /api/v1/schedules` (mặc định tuần hiện tại), `GET /api/v1/staff` (kèm trạng thái PIN). ✅ Done: scope branch (BR-59).
- [x] **UC-36 Tạo lịch** — BR-90, BR-92
  - Cross-branch không cần duyệt + audit (BR-90); ràng buộc cứng `STAFF_MAX_DAILY/WEEKLY_HOURS`, `STAFF_MIN_REST_HOURS` (BR-92); ngân sách lao động mềm `STORE_DAILY_LABOUR_BUDGET_HOURS` (override có lý do + audit); chống trùng ca. `POST /api/v1/schedules`. ✅ Done: `ScheduleService.validateConstraints` enforce giờ/nghỉ/trùng + budget mềm; A46 cashier bắt buộc posRegisterId.
- [x] **UC-37 Sửa lịch / UC-38 Xóa lịch** — BR-36, BR-37 — không sửa lịch quá khứ (BR-36, re-validate excluding self); xóa gửi email thông báo NV (BR-37). ✅ Done: `PUT/DELETE /api/v1/schedules/{id}`.
- [x] **Chấm công Check-in/out (UC-67)** — BR-38, BR-39, BR-53, BR-93
  - PIN duy nhất/branch định danh NV; **khóa được enforce** (`pinLockedUntil`) + reset khi thành công (BR-93); ảnh: thiếu ảnh → `pendingVerification=true` chờ SM xác nhận (`POST /api/v1/attendance/{id}/verify`); snapshot `scheduledStart` lúc check-in (BR-38); 1 dòng/cặp (check-out cập nhật cùng row). `POST /api/v1/attendance/check-in|check-out`. ✅ Done. ⚠️ *Tích lũy số lần sai PIN để tự khóa* hoãn sang P4 (luồng PIN-only không quy được lần sai cho 1 NV cụ thể).
- [x] **UC-39 Báo cáo chấm công** — BR-39, BR-91 — `AttendanceMetricsCalculator` tính trễ/absence/OT/early-leave động; ghép schedule↔log theo (NV, ngày). `GET /api/v1/attendance`. ✅ Done.
- [x] **UC-80 Xuất giờ công** — BR-77 — ghép cặp check-in/out; xuất **CSV** (`GET /api/v1/attendance/export`). ✅ Done CSV. ⚠️ *PDF* gộp chung với cụm export báo cáo ở **P3** (cần thư viện PDF).
- [x] **`PhotoAutoDeleteScheduler` (02:00)** — BR-72 — `AttendanceService.purgeExpiredPhotos` null `photoUrl` quá `PHOTO_RETENTION_DAYS` (90), giữ log. ✅ Done.

---

## PHASE 3 — Báo cáo & BI (`com.khoga.report`)

> Chỉ đọc (read-only query) trên dữ liệu các phase trước. Phụ thuộc: Order/OrderItem, StockTransaction, ShiftSession, AuditLog, Customer, AttendanceLog, RecipeItem/RawMaterial. Áp BR-44 scope: storemanager chỉ branch mình, ceoviewer toàn chuỗi.

- [x] **UC-28 Dashboard HQ hợp nhất / UC-29 Xuất** — BR-44 — doanh thu theo branch, top bán chạy, tỉ lệ hủy, avg transaction. `GET /api/v1/reports/hq-consolidated` (+`/export?format=csv|xlsx|pdf`). ✅ Done: `RevenueReportService.hqConsolidated` (HQ role; optional branchId); best-sellers từ `OrderItemRepository.soldByMenuItem`. **Excel/PDF done (P4)** — `ReportXlsxWriter` (POI) + `ReportPdfWriter` (OpenPDF).
- [x] **UC-40 Doanh thu cửa hàng / UC-41 Xuất** — BR-44 — sales theo phương thức cho branch của SM. `GET /api/v1/reports/store-revenue` (+`/export?format=csv|xlsx|pdf`). ✅ Done: `RevenueReportService.storeRevenue` (SM own-branch); tender breakdown + discrepancy tổng từ closed shifts. **Excel/PDF done (P4).**
- [x] **UC-76 COGS/Margin & Shrinkage (`CogsCalculator`)** — BR-66 — margin=(price−Σ(recipeQty×standardCost))/price; shrinkage = theoretical (RECIPE_DEDUCTION+PHANTOM_USAGE) vs AUDIT_ADJUSTMENT × standardCost, flag >5%. `GET /api/v1/reports/cogs`. ✅ Done: `CogsReportService` (HQ+SM) tái dùng `CogsCalculator`.
- [x] **UC-77 Lịch sử đổi giá/voucher** — BR-68 — đọc `AuditLog` (entityAffected MenuItem/Voucher) bất biến, lọc type/actor. `GET /api/v1/reports/price-history`. ✅ Done: `ChangeHistoryService.priceVoucherHistory` (HQ, paged).
- [x] **UC-78 Loyalty Liability (`LoyaltyLiabilityService`)** — BR-75 — tổng điểm tồn (đơn vị điểm) + movement issued/redeemed/expired, đối soát Opening+Issued−Redeemed−Expired=Closing. `GET /api/v1/reports/loyalty-liability`. ✅ Done. ⚠️ *expired=0* (BR-35 expiry hoãn P4 — có note trong response).
- [x] **UC-79 Labour vs Revenue (`LabourEfficiencyService`)** — BR-76, BR-77 — giờ/1tr VND, VND/giờ (không quy lương). `GET /api/v1/reports/labour`. ✅ Done: worked-hours từ attendance pairings; chain total cho HQ.
- [x] **UC-81 Z-Report ngày** — BR-78 — gộp mọi ca 1 branch 1 ngày: gross/net, voucher/point discount, VAT, refunds, tender (cash/card/VietQR), counters, banner provisional khi còn ca OPEN. `GET /api/v1/reports/z-report/{date}`. ✅ Done: `ZReportService`.
- [x] **UC-82 Anomaly hủy/refund (`AnomalyDetector`)** — BR-79 — tỉ lệ hủy/refund theo cashier (orders/cancels/refunds/vouchers/comps); flag vượt `CANCEL_REFUND_ALERT_THRESHOLD` (detective). `GET /api/v1/reports/anomaly` (+`/export?format=csv|xlsx|pdf`). ✅ Done: cashier = `order.shiftSession.user`. **Excel/PDF done (P4).**
- [x] **UC-83 Access Review** — BR-81 — đọc audit thay đổi tài khoản (entityAffected User). `GET /api/v1/reports/access-review` (ceoviewer/ssadmin). ✅ Done: `ChangeHistoryService.accessReview`.

---

## PHASE 4 — Cứng hóa & hoàn thiện (Hardening)

> Sau khi 18 subsystem chạy thông với stub/giả lập. Nâng cấp lên mức production theo NFR.

- [ ] **Integration thật**: `SmtpEmailService` (cấu hình SMTP), VietQR thật + verify HMAC webhook, `PrinterService` ESC/POS (USB/network). Toggle qua profile. ✅ Done: bật real qua config, stub vẫn dùng cho test.
- [x] **Session invalidation BR-18** — ✅ **Done 2026-06-29**: `User.tokenVersion` đóng dấu vào JWT (claim `tv`); `JwtAuthenticationFilter` nạp user mỗi request và từ chối token khi user không tồn tại / `isActive=false` / `tv` lệch. `AuthService.applyNewPassword` tăng `tokenVersion` (reset/force/change-password hủy token cũ); `changePassword` cấp lại token + refresh cookie nên phiên hiện tại sống, các thiết bị khác bị đá. `UserService.setActive` tăng version khi vô hiệu hóa. Đánh đổi: 1 DB read/request đã xác thực (không cần blacklist/Redis). *Auto-logout idle ≥30' (token refresh im lặng) chưa làm.*
- [ ] **OTP store bền** (thay in-memory bằng DB/Redis) cho đa node. *(chưa làm — OTP còn in-memory P1B.)*
- [x] **PDPA jobs**: ẩn danh PII khách >24 tháng không giao dịch (BR-72); hết hạn điểm loyalty 12 tháng (BR-35). ✅ **Done 2026-06-29**: `customer.LoyaltyExpiryService` (zero điểm khách tồn >`LOYALTY_EXPIRY_MONTHS`=12 tháng không giao dịch, ghi audit `LoyaltyExpiry` mang số điểm) + `customer.CustomerRetentionService` (xóa PII khách >`CUSTOMER_PII_RETENTION_MONTHS`=24 tháng, giữ record+lịch sử) + `scheduler.PdpaScheduler` (cron 02:30 & 03:00). **UC-78 `expired` giờ lấy thật** từ audit `LoyaltyExpiry` (gỡ `expired=0`). 2 config mới đã seed.
- [x] **i18n MSG01–MSG17** — ✅ **Done 2026-06-29**: `messages[_en].properties` (vi mặc định, en qua `Accept-Language`) chứa đủ MSG01–17 (MSG13 reserved) + `ValidationMessages[_en]`; `spring.messages.*` + `WebConfig` `AcceptHeaderLocaleResolver`; `common.i18n.Messages` resolve theo locale. `AppException.of(code, args...)` (tương thích ngược với constructor literal cũ); `GlobalExceptionHandler` + `SecurityConfig` localize 400/401/403/validation/500; `StrongPassword` → `{khoga.password.strength}`. Throw đã gắn mã: MSG03/09/10/11/12/14/16. *Còn ~170 literal khác render tiếng Việt (mặc định) — gắn mã dần theo file; seam đã sẵn.*
- [ ] **Hiệu năng & toàn vẹn**: index cho query report/lookup; rà `@Transactional` cho checkout/refund/trừ kho (atomic); làm tròn tiền VND; timezone UTC lưu/branch-local hiển thị. *(chưa rà soát hệ thống.)*
- [ ] **Test E2E + tải**: luồng login→checkout→prepare→complete; kịch bản refund/cancel; load theo NFR (100 TPS, 2000 đơn/ngày/branch). ✅ Done: bộ E2E xanh.

---

## Kiểm thử & nghiệm thu (Verification)

**Chạy app:** tạo DB `khoga_coffee_shop` (SQL Server), `./mvnw spring-boot:run` (Windows: `mvnw.cmd`). Hibernate `ddl-auto=update` tự sinh 23 bảng. Xác minh: console hiện `Started CoffeeshopApplication`; Swagger UI `http://localhost:8080/swagger-ui.html` liệt kê endpoint mới.

**Theo từng phase (smoke test qua Swagger/cURL):**
- P0: login bằng ssadmin seed → nhận JWT; gọi endpoint bảo vệ thiếu token → 401; sai role → 403; sai mật khẩu 5 lần → khóa.
- P1: tạo branch (vượt cap → 400), tạo user (email tạm + buộc đổi mật khẩu), tạo category/menu+recipe (sai đơn vị → 400), voucher (sửa code → 400), customer (thiếu consent → 400).
- P1B: forgot-password (OTP log ở stub) → reset; login HQ yêu cầu OTP, branch role không.
- P2: mở ca → thêm món → áp voucher + điểm → thanh toán (kiểm tra số tiền theo BR-70) → PREPARING (tồn kho giảm, kiểm `stock_transactions`) → READY → COMPLETED; hủy PENDING (kiểm rollback điểm/voucher); refund SM (kiểm quỹ ca); đóng ca (Z-report + cảnh báo lệch).
- P3: đối chiếu Z-report với đơn đã tạo; COGS/margin khớp recipe×standard_cost; anomaly gắn cờ khi vượt ngưỡng.

**Test tự động:** mỗi UC có test ở bước "Test"; ưu tiên test số học cho `DiscountStackingEngine`, `LoyaltyPointCalculator`, `RecipeDeductionEngine`, `ShiftReconciliation` và các guard trạng thái (hủy chỉ PENDING, đóng ca chặn order chưa terminal). Chạy 1 lớp: `./mvnw test -Dtest=<ClassName>`.

## Ghi chú quyết định & rủi ro

- **Auth MVP trước**: P0 chưa có MFA/quên-mật-khẩu → tạm thời HQ login 1 lớp cho tới P1B; chấp nhận trong môi trường dev.
- **Tích hợp ngoài là stub**: VietQR/SMTP/Printer giả lập tới P4 → test được toàn luồng mà không cần hạ tầng ngoài.
- **`ddl-auto=update`**: schema sinh từ entity, không có migration script — đổi entity là đổi bảng; cân nhắc Flyway ở P4 nếu cần kiểm soát schema.
- **OTP in-memory** ở P1B: không sống sót restart/đa node — nâng cấp P4.
- **Tồn kho cho phép âm** (BR-89) là CHỦ Ý (đo hao hụt), không phải bug — không "sửa" thành chặn về 0.
- **Khác biệt tài liệu vs code**: package gốc là `com.khoga` (RDS từng ghi nhầm `com.khoga.coffeeshop` — **đã sửa 2026-06-27**); stack thực là Spring Boot 4.1.0/Java 21 (doc từng ghi 3.x/17 — **đã sửa**). Theo code.
- **Đối soát tài liệu (2026-06-27)**: đã đối soát SRS↔RDS↔code↔plan — xem [DOCS_RECONCILIATION.md](DOCS_RECONCILIATION.md). RDS (bản 2026-06-18) đã được patch theo SRS: sửa BR-id sai (BR-11/BR-54/BR-68/BR-81), UC-id đụng độ (POS/Order/Report), bổ sung UC-02/72/83, MFA TOTP, voucher 3-state, loyalty-liability theo điểm, Z-report theo ngày, anomaly configurable, topping global, MenuItem variant, **BR-85 late-callback** (trước đó RDS đánh PAID vô điều kiện). DB-design đồng bộ code = **23 bảng** (thêm `system_configs`, `menu_item_topping_mappings`).
- **Mô hình Role (6 role, chốt 2026-06-27)**: enum `Role` = `{CASHIER, BARISTA, STORE_MANAGER, CEOVIEWER, BUSINESSADMIN, SSADMIN}` — khớp SRS §2.1. Seed sẵn `ssadmin`, `bizadmin`, `ceoviewer` (đều `mustChangePassword=true`). `BUSINESSADMIN` wire **điều chỉnh điểm KH (BR-49)** + **raw material master (UC-74/BR-63)**; `SSADMIN` super-admin. `CEOVIEWER` = read-only báo cáo chuỗi (BR-44) — **RBAC `@PreAuthorize` cho endpoint báo cáo HQ (UC-28/29/76/77/78/79/82/83) sẽ wire khi build P3**. Endpoint HQ khác hiện `SSADMIN`-only. ⚠️ Thêm `CEOVIEWER` → DB dev cũ phải drop CHECK-constraint `users.role` trước khi chạy (xem CLAUDE.md gotcha).
- **Default config theo SRS (2026-06-27)**: `VAT_RATE=10`, `MAX_ACTIVE_BRANCHES=5`, `CANCEL_REFUND_ALERT_THRESHOLD=5`, thêm `LOYALTY_MAX_REDEMPTION_LIMIT=100000`.

## Phụ thuộc tổng (rút gọn)

```
P0 (Security, Config, Audit, Integration-stub, Scheduler, Seed, Auth-MVP)
 └─ P1  Branch → User; Catalog; Voucher; Customer   (độc lập nhau, đều cần P0)
     ├─ P1B Auth nâng cao (cần SMTP stub)
     └─ P2  Inventory → POS → Order ; Staff
         └─ P3  Report (đọc tất cả)
             └─ P4  Hardening
```

