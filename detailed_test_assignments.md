# 🧪 Nhiệm Vụ Kiểm Thử Chi Tiết — 5 Người — Khoga Café

> **Mục tiêu kép**: Kiểm thử (1) giao diện + tính năng hoạt động đúng, VÀ (2) đối chiếu code thực tế với tài liệu SRS/RDS để ghi nhận sai lệch.

> [!IMPORTANT]
> Mỗi người có thêm mục **"Đối chiếu tài liệu"** — khi test, so sánh hành vi thực tế với mô tả trong SRS. Ghi nhận mọi điểm khác biệt vào bảng, dù là bug hay tài liệu sai.

## Tài liệu tham chiếu

| Tài liệu | Đường dẫn | Nội dung |
|---|---|---|
| **SRS** | [SRS.md](file:///c:/Users/pc/Desktop/coffeshop/docs/SRS.md) | Đặc tả yêu cầu phần mềm — nguồn chân lý |
| **RDS** | [RDS.md](file:///c:/Users/pc/Desktop/coffeshop/docs/RDS.md) | Thiết kế chi tiết (sequence diagram, statechart) |
| **SRS Sections** | [sections/](file:///c:/Users/pc/Desktop/coffeshop/docs/sections) | SRS chia theo chức năng |
| **RDS Sections** | [rds_sections/](file:///c:/Users/pc/Desktop/coffeshop/docs/rds_sections) | RDS chia theo module |
| **Reconciliation** | [DOCS_RECONCILIATION.md](file:///c:/Users/pc/Desktop/coffeshop/docs/DOCS_RECONCILIATION.md) | Bảng đối soát SRS ↔ RDS đã biết |

## Quy ước chung

| Ký hiệu | Ý nghĩa |
|---|---|
| ✅ | Test PASS |
| ❌ | Test FAIL (ghi bug) |
| ⚠️ | Sai lệch tài liệu (ghi nhận) |
| 🔍 | Chưa implement / thiếu tính năng |
| N/A | Không áp dụng |

---

# 👤 NGƯỜI 1 — Xác thực, Phân quyền & Hồ sơ

## Phạm vi

| Nhóm chức năng | UC-IDs | Tài liệu SRS |
|---|---|---|
| Authentication | UC-01, UC-02, UC-03, UC-04, UC-05, UC-06 | §3.2.1 → §3.2.7 |
| Profile | UC-07, UC-08, UC-09 | §3.2.8 → §3.2.10 |
| User Management | UC-10, UC-11, UC-12, UC-13, UC-14 | §3.2.11 → §3.2.15 |
| RBAC | §3.2.0 Permission Matrix | §3.1.3 Screen Authorization |

## Tài liệu cần đọc trước

- [03_2_system_access_security.md](file:///c:/Users/pc/Desktop/coffeshop/docs/sections/03_2_system_access_security.md) — SRS chi tiết auth
- [04_detailed_3_1_system_access_security.md](file:///c:/Users/pc/Desktop/coffeshop/docs/rds_sections/04_detailed_3_1_system_access_security.md) — RDS auth
- [05_detailed_3_2_user_management.md](file:///c:/Users/pc/Desktop/coffeshop/docs/rds_sections/05_detailed_3_2_user_management.md) — RDS user mgmt

## A. Checklist Giao diện

### A1. Màn hình Login (Screen 1)
- [ ] **Có đủ field**: Username (text, max 50), Password (masked, max 255)
- [ ] **Có nút LOGIN** và link **Forgot Password**
- [ ] **Logo** hiển thị đúng
- [ ] **Responsive**: hiển thị tốt trên mobile portrait (POS App) và desktop (Web Admin)
- [ ] **Error state**: hiển thị lỗi khi nhập sai (MSG02: "Incorrect username or password. Remaining attempts: {count}")
- [ ] So sánh với **SRS §3.2.1.1 mockup** — layout có khớp không?

### A2. Màn hình Force Password Change (Screen 5)
- [ ] Hiển thị khi `must_change_password = true` (BR-12)
- [ ] Có field: New Password, Confirm Password
- [ ] **Chặn điều hướng** đi bất kỳ đâu cho đến khi đổi xong (BR-12)

### A3. Màn hình Forgot Password (Screen 2)
- [ ] Field: Email Address (text, max 100)
- [ ] Nút **Send OTP** và link **Back to Login**
- [ ] So sánh với **SRS §3.2.4.1 mockup**

### A4. Màn hình OTP Verification (Screen 3)
- [ ] Field: Verification Code (6 digit, max 6)
- [ ] Nút **Verify Code** và link **Resend Code**
- [ ] Resend bị disable 60 giây (cooldown timer hiển thị)

### A5. Màn hình Set New Password (Screen 4)
- [ ] Field: New Password, Confirm Password
- [ ] Nút **Save** (SRS §3.2.6.1)

### A6. Màn hình View Profile (Screen 6)
- [ ] Hiển thị: Full Name, Email, Phone, Role, Branch (nếu có), Created At
- [ ] Nút/link đến **Edit Profile** và **Change Password**

### A7. Màn hình Edit Profile (Screen 7)
- [ ] Chỉ cho sửa: Phone, Email (theo SRS UC-08)
- [ ] **KHÔNG cho sửa**: Role, Username, Branch (SRS §3.2.9)

### A8. Màn hình Change Password (Screen 8)
- [ ] Field: Current Password, New Password, Confirm New Password
- [ ] Nút **Save Changes**
- [ ] So sánh với **SRS §3.2.3.1 mockup**

### A9. User Management — Web Admin
- [ ] **Account List (Screen 10)**: danh sách user, filter theo role/status
- [ ] **Add User Form (Screen 11)**: field gồm Username, Full Name, Email, Phone, Role (dropdown 6 role), Branch (dropdown), Is Active
- [ ] **User Detail (Screen 13)**: xem chi tiết + audit logs
- [ ] **Edit User Form (Screen 12)**: sửa thông tin user
- [ ] Chỉ **ssadmin** mới thấy menu User Management (SRS §3.1.3 Screen Authorization)

### A10. POS App — Login & Profile
- [ ] Login Screen hiển thị đúng trên Flutter
- [ ] Profile Screen hiển thị đúng
- [ ] Change Password hoạt động trên POS App

## B. Checklist Tính năng

### B1. UC-01 Login — Main Flow + Alternative
| # | Test Case | Kết quả | Ghi chú |
|---|---|---|---|
| 1 | Đăng nhập đúng username/password → redirect đúng portal theo role | | |
| 2 | HQ role (ceoviewer) → redirect Web Admin Dashboard | | |
| 3 | HQ role (businessadmin) → Web Admin, chỉ thấy menu Catalog/Voucher/Customer | | |
| 4 | HQ role (ssadmin) → Web Admin, chỉ thấy menu User/Branch/Settings | | |
| 5 | POS role (cashier) → POS App, ShiftGate | | |
| 6 | POS role (barista) → POS App, BaristaPortalScreen | | |
| 7 | POS role (storemanager) → POS App, HomeScreen | | |
| 8 | **AT1**: Sai password → hiển thị MSG02 với remaining attempts | | |
| 9 | **AT3**: 5 lần sai → khóa 15 phút (BR-11) | | |
| 10 | **AT2**: `must_change_password = true` → redirect Force Password Change (BR-12) | | |
| 11 | `is_active = false` → chặn login (BR-10) | | |
| 12 | **AT4/BR-83**: HQ role + `HQ_MFA_REQUIRED` on → yêu cầu MFA 6 digit | | |
| 13 | MFA: 3 lần sai → lockout (BR-17 reuse) | | |

### B2. UC-02 Logout
| # | Test Case | Kết quả | Ghi chú |
|---|---|---|---|
| 1 | Click Logout → hiện confirmation modal | | |
| 2 | Confirm → clear session, redirect Login | | |
| 3 | **AT1**: Cashier có shift đang mở → msg "shift session remains open" (BR-60) | | |
| 4 | Logout time được ghi log (BR-13) | | |

### B3. UC-03/04/05 Forgot Password → OTP → Set New Password
| # | Test Case | Kết quả | Ghi chú |
|---|---|---|---|
| 1 | Nhập email tồn tại → gửi OTP, redirect OTP screen | | |
| 2 | Email không tồn tại → msg generic (chống harvesting) | | |
| 3 | OTP đúng → redirect Set New Password | | |
| 4 | OTP sai/hết hạn 10 phút → msg lỗi (BR-16) | | |
| 5 | 3 lần OTP sai → khóa recovery session (BR-17) | | |
| 6 | Resend Code: disable 60s, sau đó cho gửi lại | | |
| 7 | Set New Password: phải khớp confirm, phải ≥8 ký tự + upper/lower/number/special (BR-14) | | |
| 8 | Mật khẩu mới không được trùng mật khẩu cũ (BR-15) | | |

### B4. UC-06 Force Password Change
| # | Test Case | Kết quả | Ghi chú |
|---|---|---|---|
| 1 | User mới login lần đầu → bắt đổi mật khẩu trước | | |
| 2 | Không thể navigate đi chỗ khác (BR-12) | | |
| 3 | Sau khi đổi → `must_change_password` = false, redirect portal | | |

### B5. UC-07/08/09 Profile
| # | Test Case | Kết quả | Ghi chú |
|---|---|---|---|
| 1 | Xem profile: hiển thị đủ thông tin | | |
| 2 | Edit profile: chỉ cho sửa phone/email | | |
| 3 | Change password: validate mật khẩu cũ đúng | | |
| 4 | Mật khẩu mới phải thỏa BR-14, BR-15 | | |
| 5 | Sau đổi mật khẩu, session khác bị terminate | | |

### B6. UC-10→14 User Management (only ssadmin)
| # | Test Case | Kết quả | Ghi chú |
|---|---|---|---|
| 1 | **UC-10**: Xem danh sách user, filter active/inactive/role | | |
| 2 | **UC-11**: Tạo user mới — validate unique username + email + phone (BR-57/58) | | |
| 3 | UC-11: Auto-generate username (BR-58), temporary password | | |
| 4 | UC-11: HQ role (ceoviewer/businessadmin/ssadmin) → `store_id` = null | | |
| 5 | UC-11: Branch role → bắt buộc chọn branch | | |
| 6 | **UC-12**: Sửa user — KHÔNG cho tự sửa role/status mình (BR-82) | | |
| 7 | **UC-13**: Xem chi tiết user + audit log | | |
| 8 | **UC-14**: Deactivate user → `is_active = false`, chặn login | | |

### B7. RBAC — Screen Authorization (SRS §3.1.3)
| # | Test Case | Kết quả | Ghi chú |
|---|---|---|---|
| 1 | `ceoviewer` chỉ thấy: Dashboard + Reports (read-only) | | |
| 2 | `businessadmin` chỉ thấy: Catalog + Voucher + Customer | | |
| 3 | `ssadmin` chỉ thấy: User Management + Branch + Settings | | |
| 4 | `ceoviewer` KHÔNG thể tạo/sửa/xóa bất kỳ dữ liệu nào | | |
| 5 | `businessadmin` KHÔNG thấy User Management, Settings, Reports | | |
| 6 | `ssadmin` KHÔNG thấy Catalog, Voucher, Customer, Reports | | |

## C. Đối chiếu Tài liệu

> Test xong mỗi mục, so sánh hành vi thực tế với SRS/RDS và ghi vào bảng:

| Mã | Mô tả SRS/RDS | Hành vi thực tế | Khớp? | Ghi chú |
|---|---|---|---|---|
| A1 | BR-11: 5 lần sai → khóa 15' | | | RDS cũ ghi sai BR-15 |
| A2 | SM mở khóa nhân viên branch | | | RDS chỉ có ssadmin |
| A3 | BR-83: MFA cho HQ role (email OTP hoặc TOTP) | | | Code P1 chỉ làm email-OTP |
| A4 | UC-02 Logout + BR-13 + BR-60 | | | RDS thiếu flow |
| A5 | UC-83: Access Review Report | | | RDS thiếu |
| A6 | BR-82: Không tự sửa role/quyền/trạng thái mình | | | RDS hẹp hơn |
| A7 | UC-11: Unique email + phone (BR-57/58) | | | RDS chỉ check username |
| A8 | SRS §3.1.3: 6 role riêng biệt vs code role enum | | | Kiểm tra enum ROLE |
| A9 | SRS: 7 role gồm CEOVIEWER | | | Code đã seed chưa? |
| | *Thêm dòng khi phát hiện sai lệch mới...* | | | |

---

# 👤 NGƯỜI 2 — Catalog, Category, Topping & Nguyên liệu

## Phạm vi

| Nhóm chức năng | UC-IDs | Tài liệu SRS |
|---|---|---|
| Menu & Categories | UC-15, UC-68, UC-69, UC-16, UC-17, UC-70, UC-18, UC-19, UC-72 | §3.3 |
| Topping & Options | UC-71 | §3.3 |
| Raw Material | UC-74 | §3.5.0 (Inventory section) |
| Menu Item Detail | UC-68 | §3.3 |

## Tài liệu cần đọc trước

- [03_3_menu_management.md](file:///c:/Users/pc/Desktop/coffeshop/docs/sections/03_3_menu_management.md) — SRS Menu
- [03_4_category_management.md](file:///c:/Users/pc/Desktop/coffeshop/docs/sections/03_4_category_management.md) — SRS Category
- [06_detailed_3_3_menu_category.md](file:///c:/Users/pc/Desktop/coffeshop/docs/rds_sections/06_detailed_3_3_menu_category.md) — RDS Menu/Category

## A. Checklist Giao diện

### A1. Menu & Categories Management (Screen 14) — Web Admin
- [ ] Hiển thị danh sách menu items với: Name, Price, Category, Is Active, Image
- [ ] **Search/filter** theo tên, category
- [ ] Nút **Add Menu Item** chuyển đến form tạo mới
- [ ] Click item → chi tiết hoặc edit form
- [ ] Chỉ **businessadmin** mới thấy (SRS §3.1.3)

### A2. Add Menu Item Form (Screen 17)
- [ ] **Field đủ theo SRS §3.1.6 Entity #3**: Name (max 100), Price (decimal), Category (dropdown), Description (text), Image URL, Barcode (max 50, unique), Abbreviation (max 50, auto-gen)
- [ ] **Variant/Size**: có hỗ trợ biến thể S/M/L + giá riêng không? (Code có `parentItemId`/`sizeName`/`sku` — SRS yêu cầu)
- [ ] **Recipe section**: gán nguyên liệu + số lượng cần (Recipe Items)
- [ ] **Topping section**: chọn topping áp dụng cho item này

### A3. Category Management (Screen 15/16)
- [ ] Danh sách category: Name, Description, Is Active, số item thuộc category
- [ ] Add Category: Name (max 100, required), Description (optional), Is Active
- [ ] Edit Category: sửa thông tin
- [ ] Delete Category: modal confirm → chỉ xóa được khi không có menu item (hoặc set null FK)

### A4. Raw Material Master (Screen 50)
- [ ] **Field theo SRS Entity #10**: Code (max 20, unique, immutable), Name (max 100), Unit (max 20), Suggested Min Threshold, Standard Cost, Is Active, Category (INGREDIENTS/PACKAGING)
- [ ] Chỉ **businessadmin** mới truy cập (SRS §3.1.3)
- [ ] Soft-delete: set Inactive, ẩn khỏi recipe/import selections (BR-64)

### A5. POS App — Hiển thị Menu
- [ ] POS Screen hiển thị danh mục category + menu items
- [ ] Item không active hoặc không available tại branch → ẩn khỏi POS
- [ ] Search/filter hoạt động trên POS

## B. Checklist Tính năng

### B1. UC-15/68/69 View Menu & Categories
| # | Test Case | Kết quả | Ghi chú |
|---|---|---|---|
| 1 | Xem danh sách menu items — đầy đủ thông tin | | |
| 2 | **UC-68**: Click vào item → xem chi tiết (price, description, abbreviation, toppings, recipe) | | |
| 3 | **UC-69**: Xem categories — hiển thị item count | | |
| 4 | Filter theo category hoạt động đúng | | |
| 5 | Menu hiển thị 2 mức availability: active toàn chuỗi AND available tại branch (BR-25) | | |

### B2. UC-16/17/70 Category CRUD
| # | Test Case | Kết quả | Ghi chú |
|---|---|---|---|
| 1 | **UC-16**: Tạo category — validate name required, max 100 | | |
| 2 | **UC-17**: Sửa category — name, description, is_active | | |
| 3 | **UC-70**: Xóa category — confirm modal → xóa thành công nếu trống | | |
| 4 | UC-70: Xóa category có menu items → menu items.category_id set null (SRS §3.1.6) | | |

### B3. UC-18/19/72 Menu Item CRUD
| # | Test Case | Kết quả | Ghi chú |
|---|---|---|---|
| 1 | **UC-18**: Tạo menu item + recipe — validate đầy đủ field bắt buộc | | |
| 2 | UC-18: Tạo với barcode → unique check | | |
| 3 | UC-18: Gán recipe (chọn raw material + quantity_required) | | |
| 4 | UC-18: Auto-generate abbreviation (SRS) | | |
| 5 | **UC-19**: Sửa menu item — sửa giá → audit log (BR-68) | | |
| 6 | **UC-72**: Xóa (soft-delete) → `is_deleted = true`, ẩn khỏi POS (BR-28) | | |
| 7 | Variant/Size: tạo biến thể S/M/L cho 1 menu item | | |

### B4. UC-71 Manage Toppings & Options
| # | Test Case | Kết quả | Ghi chú |
|---|---|---|---|
| 1 | Tạo topping: Name (max 100), Price (decimal), Is Active | | |
| 2 | **Mô hình topping**: Global topping hay per-item? (Code = global + `MenuItemToppingMapping`) | | |
| 3 | Gán topping cho menu item qua mapping table | | |
| 4 | Sửa, deactivate topping | | |
| 5 | Topping có recipe riêng (gán raw material) | | |

### B5. UC-74 Raw Material Master
| # | Test Case | Kết quả | Ghi chú |
|---|---|---|---|
| 1 | Tạo raw material: Code (unique, immutable), Name, Unit, Category (INGREDIENTS/PACKAGING) | | |
| 2 | Set Standard Cost (cho COGS BR-66) | | |
| 3 | Set Suggested Min Threshold | | |
| 4 | Soft-delete: set Inactive → ẩn khỏi recipe selections (BR-64) | | |
| 5 | Code immutable sau khi tạo — không cho sửa | | |
| 6 | Unit locked khi có stock transaction reference (BR-63) | | |

## C. Đối chiếu Tài liệu

| Mã | Mô tả SRS/RDS | Hành vi thực tế | Khớp? | Ghi chú |
|---|---|---|---|---|
| A10 | Topping global + `MenuItemToppingMapping` (code) vs per-item FK (RDS) | | | Code = chuẩn |
| A11 | MenuItem variant S/M/L (`parentItemId`/`sizeName`/`sku`) | | | RDS thiếu |
| A12 | BR-68: audit log khi đổi giá (CREATE + PRICE_UPDATE) | | | RDS chỉ log CREATE |
| A13 | `BranchMenuStatus` có `lastUpdatedBy/At`? | | | SRS yêu cầu, code/RDS thiếu |
| A14 | UC-72 Delete Menu — có soft-delete đúng BR-28? | | | RDS thiếu sequence |
| A15 | UC-15 list menu có tham số store context? (BR-25) | | | RDS thiếu |
| A35 | RawMaterial: `standardCost` + `isActive` có trong code? | | | RDS cũ bỏ |
| A36 | UC-74 Raw Material Master có trong code chưa? | | | RDS cũ thiếu |
| | *Thêm dòng khi phát hiện sai lệch mới...* | | | |

---

# 👤 NGƯỜI 3 — POS Bán hàng, Ca làm & Barista

## Phạm vi

| Nhóm chức năng | UC-IDs | Tài liệu SRS |
|---|---|---|
| Shift Management | UC-44, UC-53 | §3.6 POS Transaction |
| POS Checkout | UC-45, UC-46, UC-47, UC-48, UC-49, UC-50, UC-51, UC-52 | §3.6 |
| Barista Queue | UC-57, UC-58, UC-59, UC-60 | §3.7 Order Prep |
| Auto-Deduct | UC-62 | §3.5 Inventory |
| Order History (POS) | UC-54, UC-73 | §3.7 |

## Tài liệu cần đọc trước

- [03_6_pos_transaction.md](file:///c:/Users/pc/Desktop/coffeshop/docs/sections/03_6_pos_transaction.md) — SRS POS
- [03_7_order_management.md](file:///c:/Users/pc/Desktop/coffeshop/docs/sections/03_7_order_management.md) — SRS Order
- [10_detailed_3_7_pos_transaction.md](file:///c:/Users/pc/Desktop/coffeshop/docs/rds_sections/10_detailed_3_7_pos_transaction.md) — RDS POS
- [11_detailed_3_8_order_management.md](file:///c:/Users/pc/Desktop/coffeshop/docs/rds_sections/11_detailed_3_8_order_management.md) — RDS Order

## A. Checklist Giao diện

### A1. Open Shift Screen (Screen 34)
- [ ] **Field**: POS Register ID (text, max 50, required), Starting Cash (decimal VND, required)
- [ ] Nút **Open Shift**
- [ ] Nếu đã có shift mở → không cho mở thêm (UC-44 precondition)

### A2. POS Checkout Grid & Cart (Screen 35)
- [ ] **Bên trái**: Menu grid — category tabs, menu items dạng grid/card
- [ ] **Bên phải**: Cart — danh sách items đã chọn, quantity, subtotal
- [ ] **Search bar** (UC-47): tìm theo tên, abbreviation, barcode
- [ ] **Nút**: Membership Lookup, Apply Voucher, Redeem Points, Payment, Order History, Close Shift
- [ ] **Landscape orientation** trên tablet

### A3. Payment Checkout Modal (Screen 38)
- [ ] Chọn phương thức: CASH, CARD, VIETQR
- [ ] Hiển thị: Subtotal, Discount, Tax (VAT), Total
- [ ] **CASH**: nhập số tiền nhận, tính tiền thừa
- [ ] **VIETQR**: hiển thị QR code, auto-confirm khi callback (BR-84)

### A4. Close Shift Screen (Screen 41)
- [ ] **Field**: Ending Cash (counted, required)
- [ ] Hiển thị: Starting Cash, Expected Cash, Cash Sales, Discrepancy
- [ ] Discrepancy > 100k VND → cảnh báo + email SM (BR-04)

### A5. Barista Portal (Screen 42)
- [ ] Hiển thị queue theo cột: PENDING, PREPARING, READY
- [ ] Mỗi order card: order number, items, toppings, timestamp
- [ ] Nút **Start Prep**, **Ready**, **Print Label**
- [ ] Landscape mode trên tablet

### A6. Report Issue Screen (Screen 43)
- [ ] Modal flag issue: reason text, chọn order
- [ ] Notify cashier/manager

## B. Checklist Tính năng

### B1. UC-44 Open Shift
| # | Test Case | Kết quả | Ghi chú |
|---|---|---|---|
| 1 | Nhập POS Register ID + Starting Cash → mở ca thành công | | |
| 2 | `SHIFT_SESSION` record tạo: status=OPEN, start_time, starting_cash | | |
| 3 | Không mở ca nếu đã có ca OPEN cho user này (BR-03) | | |
| 4 | Sau mở ca → redirect POS Checkout Grid | | |

### B2. UC-45/46/47 Cart Operations
| # | Test Case | Kết quả | Ghi chú |
|---|---|---|---|
| 1 | **UC-45**: Click/tap menu item → thêm vào cart, quantity = 1 | | |
| 2 | UC-45: Chọn topping cho item (modal) | | |
| 3 | UC-45: Validate item available tại branch (`BranchMenuStatus`) | | |
| 4 | **UC-46**: Tăng/giảm quantity, xóa item khỏi cart | | |
| 5 | UC-46: Sửa topping trên item đã thêm | | |
| 6 | **UC-47**: Search by name → filter grid | | |
| 7 | UC-47: Search by abbreviation → filter grid | | |
| 8 | UC-47: Search by barcode/SKU → filter grid | | |
| 9 | Subtotal recalculate đúng khi thay đổi cart | | |

### B3. UC-48/49/50 Discount & Membership
| # | Test Case | Kết quả | Ghi chú |
|---|---|---|---|
| 1 | **UC-48**: Nhập voucher code → validate + apply discount | | |
| 2 | UC-48: Voucher hết hạn → reject | | |
| 3 | UC-48: Voucher min_order_value → reject nếu subtotal thấp hơn | | |
| 4 | **UC-49**: Redeem loyalty points → tính discount tương ứng | | |
| 5 | UC-49: Cap redemption (BR-02: `LOYALTY_MAX_REDEMPTION_PERCENT/LIMIT`) | | |
| 6 | **UC-50**: Lookup customer by phone → hiển thị tên, points balance | | |
| 7 | UC-50: Customer không tìm thấy → offer đăng ký mới | | |

### B4. UC-51/52 Payment & Invoice
| # | Test Case | Kết quả | Ghi chú |
|---|---|---|---|
| 1 | **UC-51**: Thanh toán CASH → nhập tiền nhận, tính thừa | | |
| 2 | UC-51: Thanh toán VIETQR → show QR, wait callback (BR-84) | | |
| 3 | UC-51: VietQR timeout → Payment Retry modal (Screen 39) | | |
| 4 | UC-51: Order saved: `payment_status=COMPLETED`, `order_status=PENDING` | | |
| 5 | **UC-52**: In receipt sau payment → receipt data đúng | | |
| 6 | Order number 3 digit, reset daily per branch (SRS Entity #7 field 3) | | |
| 7 | Tax (VAT) tính đúng theo `VAT_RATE` config | | |
| 8 | Loyalty points earned = based on Net Total Payable (BR-69) | | |

### B5. UC-53 Close Shift
| # | Test Case | Kết quả | Ghi chú |
|---|---|---|---|
| 1 | Nhập Ending Cash → tính discrepancy | | |
| 2 | Discrepancy > 100k → cảnh báo + email SM (BR-04) | | |
| 3 | Shift status → CLOSED, end_time recorded | | |
| 4 | Không close nếu còn order PENDING/PREPARING (BR-03 guard) | | |

### B6. UC-57/58/59/60 Barista Queue
| # | Test Case | Kết quả | Ghi chú |
|---|---|---|---|
| 1 | **UC-57**: Queue hiển thị đơn PENDING/PREPARING/READY đúng thứ tự | | |
| 2 | **UC-58**: Tap "Start Prep" → order PENDING→PREPARING | | |
| 3 | UC-58: Start Prep triggers auto-deduct inventory (UC-62, BR-65) | | |
| 4 | UC-58: Tap "Ready" → PREPARING→READY | | |
| 5 | **UC-59**: Print label → data đúng (order number, item name, toppings) | | |
| 6 | **UC-60**: Report Issue → flag order, notify POS | | |

### B7. UC-62 Auto-Deduct Inventory
| # | Test Case | Kết quả | Ghi chú |
|---|---|---|---|
| 1 | Barista tap Start Prep → hệ thống trừ kho theo recipe | | |
| 2 | Trừ cả recipe của **toppings** (BR-65) | | |
| 3 | Stock transaction logged: type=RECIPE_DEDUCTION | | |
| 4 | Nếu nguyên liệu hết → hành vi? (low stock alert?) | | |

### B8. Non-Screen Functions
| # | Test Case | Kết quả | Ghi chú |
|---|---|---|---|
| 1 | **Auto-Close Shift 23:59**: ca chưa đóng bị auto-close | | |
| 2 | Guard: không auto-close nếu còn order chưa terminal (BR-03) | | |
| 3 | **Order Timeout 15'**: order PENDING > 15 phút → auto ABANDONED | | |
| 4 | **READY Abandon Timeout**: READY > `READY_ABANDON_TIMEOUT` → ABANDONED (BR-88) | | |

## C. Đối chiếu Tài liệu

| Mã | Mô tả SRS/RDS | Hành vi thực tế | Khớp? | Ghi chú |
|---|---|---|---|---|
| A27 | BR-85: VietQR late callback cho đơn đã hủy → KHÔNG hồi sinh | | | **NGHIÊM TRỌNG** |
| A28 | UC-id xung đột POS/Order (RDS vs SRS) | | | RDS sai UC-ID |
| A29 | BR-88: READY_ABANDON_TIMEOUT cấu hình (RDS hardcode 15') | | | |
| A30 | SM force-close READY→ABANDONED | | | RDS thiếu |
| A31 | BR-04: lệch quỹ > 100k → email SM | | | RDS thiếu |
| A32 | Auto-close ca 23:59 + guard BR-03 | | | |
| A33 | BR-65: trừ kho cả topping | | | RDS chỉ nói "recipe" |
| A34 | Enum stock transaction: IMPORT/EXPORT/AUDIT_ADJ/RECIPE_DEDUCTION/PHANTOM | | | SRS text cũ sai |
| A38 | BR-84: VietQR auto-confirm (không cần xác nhận tay) | | | RDS có `confirmQrPaid()` |
| | *Thêm dòng khi phát hiện sai lệch mới...* | | | |

---

# 👤 NGƯỜI 4 — Đơn hàng, Khách hàng & Voucher

## Phạm vi

| Nhóm chức năng | UC-IDs | Tài liệu SRS |
|---|---|---|
| Voucher Management | UC-20, UC-21, UC-22, UC-23 | §3.10 Promotion Campaign |
| Customer Management | UC-24, UC-25, UC-26, UC-27 | §3.8 Customer Membership |
| Order History & Refund | UC-54, UC-73, UC-55, UC-75 | §3.7 Order Management |
| Loyalty Points | UC-49 (verify kết quả) | §3.8 |

## Tài liệu cần đọc trước

- [03_10_promotion_campaign.md](file:///c:/Users/pc/Desktop/coffeshop/docs/sections/03_10_promotion_campaign.md) — SRS Voucher
- [03_8_customer_membership.md](file:///c:/Users/pc/Desktop/coffeshop/docs/sections/03_8_customer_membership.md) — SRS Customer
- [03_7_order_management.md](file:///c:/Users/pc/Desktop/coffeshop/docs/sections/03_7_order_management.md) — SRS Order
- [07_detailed_3_4_voucher.md](file:///c:/Users/pc/Desktop/coffeshop/docs/rds_sections/07_detailed_3_4_voucher.md) — RDS Voucher
- [08_detailed_3_5_customer_membership.md](file:///c:/Users/pc/Desktop/coffeshop/docs/rds_sections/08_detailed_3_5_customer_membership.md) — RDS Customer

## A. Checklist Giao diện

### A1. Voucher List (Screen 19) — Web Admin
- [ ] Danh sách voucher: Code, Discount Type, Value, Start/End Date, Status, Usage Count
- [ ] Filter/search theo code, status
- [ ] Status hiển thị: SCHEDULED / ACTIVE / EXPIRED (tính động theo BR-52)
- [ ] Chỉ **businessadmin** truy cập

### A2. Voucher Form — Add (Screen 20) / Edit (Screen 21)
- [ ] **Field theo SRS Entity #12**: Code (max 50, unique), Discount Type (PERCENTAGE/FIXED_AMOUNT), Discount Value, Min Order Value, Start Date, End Date, Is Active, Usage Limit Per Customer, Max Total Uses, Max Discount Amount (cap %), Description (max 250)
- [ ] Validate: Discount Value [1..100] cho PERCENTAGE (A19)
- [ ] Validate: Start Date < End Date
- [ ] Validate: Max Discount Amount chỉ cho PERCENTAGE (BR-42)

### A3. Customer List (Screen 22) — Web Admin
- [ ] Danh sách: Name, Phone, Email, Points Balance, Created At
- [ ] Search by phone/name
- [ ] **Truy cập**: businessadmin + storemanager + cashier (SRS §3.1.3)

### A4. Customer Form — Add/Edit
- [ ] **Field theo SRS Entity #5**: Phone (max 20, unique, required), Full Name (max 100, required), Email (max 100, optional), Birth Date (optional — code có, SRS thiếu)
- [ ] Points khởi tạo = 0

### A5. Customer History (Screen 22 detail)
- [ ] Hiển thị: lịch sử đơn hàng, point accumulation ledger, redemption history (UC-27)

### A6. POS App — Order History
- [ ] **Order History Screen**: danh sách đơn bán ra trong ca/branch
- [ ] **Order Detail Screen**: chi tiết item, payment, trạng thái
- [ ] **Order Labels**: in nhãn đơn

## B. Checklist Tính năng

### B1. UC-20/21/22/23 Voucher CRUD
| # | Test Case | Kết quả | Ghi chú |
|---|---|---|---|
| 1 | **UC-20**: Xem danh sách voucher — status tính động (SCHEDULED/ACTIVE/EXPIRED theo BR-52) | | |
| 2 | **UC-21**: Tạo voucher — validate tất cả field | | |
| 3 | UC-21: Code unique — trùng thì lỗi | | |
| 4 | UC-21: PERCENTAGE với value > 100 → reject | | |
| 5 | UC-21: PERCENTAGE + Max Discount Amount (cap) (BR-42) | | |
| 6 | **UC-22**: Sửa voucher — cho sửa dates, usage limits | | |
| 7 | UC-22: Audit log ghi nhận thay đổi (BR-68) | | |
| 8 | **UC-23**: Deactivate voucher → `is_active = false`, chặn sử dụng ngay (BR-41) | | |
| 9 | UC-23: Deactivate = TERMINAL → không cho reactivate (BR-41, A18) | | |
| 10 | Voucher đã hết `max_total_uses` → tự động không cho dùng | | |
| 11 | Voucher `usage_limit_per_customer` → khách dùng quá lần → reject | | |

### B2. UC-24/25/26/27 Customer CRUD
| # | Test Case | Kết quả | Ghi chú |
|---|---|---|---|
| 1 | **UC-24**: Xem danh sách customer, search by phone | | |
| 2 | **UC-25**: Tạo customer — validate phone unique, name required | | |
| 3 | UC-25: Cashier cũng có thể tạo customer (SRS UC-25 actor) | | |
| 4 | **UC-26**: Sửa customer — businessadmin + cashier (UC-26 actor) | | |
| 5 | **UC-27**: Xem lịch sử: đơn hàng + point ledger + redemption history | | |
| 6 | Manual point adjustment by businessadmin + reason required (BR-49, A23) | | |

### B3. Loyalty Points Verification
| # | Test Case | Kết quả | Ghi chú |
|---|---|---|---|
| 1 | Mua hàng → points earned dựa trên Net Total Payable (BR-69) | | |
| 2 | Points tích lũy đúng trên customer record | | |
| 3 | Redeem points → trừ đúng số điểm, discount đúng | | |
| 4 | Cap redemption: `LOYALTY_MAX_REDEMPTION_PERCENT` + `LIMIT` (BR-02) | | |
| 5 | Points hết hạn sau 12 tháng (BR-35) | | |

### B4. UC-54/73/55/75 Order History & Refund
| # | Test Case | Kết quả | Ghi chú |
|---|---|---|---|
| 1 | **UC-54**: Cashier xem order history trong ca hiện tại | | |
| 2 | **UC-73**: Xem order detail — items, payments, toppings, timestamps | | |
| 3 | **UC-55**: Cancel order PENDING → nhập reason + notes → CANCELLED | | |
| 4 | UC-55: Không cancel order đã qua PENDING (BR-05) | | |
| 5 | UC-55: `ORDER_CANCELLATION` record tạo đúng | | |
| 6 | **UC-75**: SM Refund/Comp cho order PREPARING/READY/COMPLETED | | |
| 7 | UC-75: SM phải authorize (login/PIN) | | |
| 8 | UC-75: Chọn REFUND (full/partial) hoặc COMP_REMAKE | | |
| 9 | UC-75: `ORDER_REFUND` record tạo: sm_id, cashier_id, amount, type, reason | | |
| 10 | UC-75: REFUND → `payment_status` → REFUNDED/PARTIALLY_REFUNDED | | |

## C. Đối chiếu Tài liệu

| Mã | Mô tả SRS/RDS | Hành vi thực tế | Khớp? | Ghi chú |
|---|---|---|---|---|
| A16 | UC-27 = View Customer History (SRS) vs Redeem Points (RDS) | | | RDS sai |
| A17 | Voucher status 3-state dynamic (SRS BR-52) vs 4-state (RDS) | | | SRS = chuẩn |
| A18 | Deactivate = terminal, không reactivate (BR-41) | | | RDS cho reactivate |
| A19 | Discount % range [1..100] (RDS, nhận vào SRS) | | | |
| A20 | BR audit voucher = BR-68 (SRS) vs BR-81 (RDS) | | | RDS sai BR-ID |
| A22 | Voucher.description field (SRS có, RDS thiếu) | | | Check code |
| A23 | Manual point adjustment + reason (BR-49) | | | RDS thiếu |
| A24 | Loyalty cap + expiry 12 tháng (BR-02, BR-35) | | | RDS thiếu |
| A25 | Points base = Net Total Payable (BR-69) | | | RDS mơ hồ |
| A26 | Customer `birthDate` field | | | SRS thiếu, code có |
| A37 | Cancel order: hoàn kho hay không? (BR-07) | | | SRS mâu thuẫn nội bộ |
| | *Thêm dòng khi phát hiện sai lệch mới...* | | | |

---

# 👤 NGƯỜI 5 — Chi nhánh, Kho, Nhân viên, Báo cáo & Cài đặt

## Phạm vi

| Nhóm chức năng | UC-IDs | Tài liệu SRS |
|---|---|---|
| Branch Management | UC-63, UC-64, UC-65 | §3.13 System Configuration |
| Inventory & Stock | UC-31, UC-32, UC-33, UC-34, UC-61 | §3.5 Inventory |
| Staff & Schedule | UC-35, UC-36, UC-37, UC-38, UC-39, UC-66, UC-80 | §3.9 Staff Management |
| Reports (HQ) | UC-28, UC-29, UC-76, UC-77, UC-78, UC-79, UC-81, UC-82, UC-83 | §3.12 Dashboard Reporting |
| Reports (Branch) | UC-40, UC-41 | §3.12 |
| System Config | UC-30, UC-42 | §3.13 |

## Tài liệu cần đọc trước

- [03_5_inventory_management.md](file:///c:/Users/pc/Desktop/coffeshop/docs/sections/03_5_inventory_management.md) — SRS Inventory
- [03_9_staff_management.md](file:///c:/Users/pc/Desktop/coffeshop/docs/sections/03_9_staff_management.md) — SRS Staff
- [03_12_dashboard_reporting.md](file:///c:/Users/pc/Desktop/coffeshop/docs/sections/03_12_dashboard_reporting.md) — SRS Reports
- [03_13_system_configuration.md](file:///c:/Users/pc/Desktop/coffeshop/docs/sections/03_13_system_configuration.md) — SRS Config
- [09_detailed_3_6_inventory.md](file:///c:/Users/pc/Desktop/coffeshop/docs/rds_sections/09_detailed_3_6_inventory.md) — RDS Inventory
- [12_detailed_3_9_staff_management.md](file:///c:/Users/pc/Desktop/coffeshop/docs/rds_sections/12_detailed_3_9_staff_management.md) — RDS Staff
- [13_detailed_3_10_reports.md](file:///c:/Users/pc/Desktop/coffeshop/docs/rds_sections/13_detailed_3_10_reports.md) — RDS Reports
- [14_detailed_3_11_config_branch.md](file:///c:/Users/pc/Desktop/coffeshop/docs/rds_sections/14_detailed_3_11_config_branch.md) — RDS Config/Branch

## A. Checklist Giao diện

### A1. Branch Management — Web Admin (ssadmin only)
- [ ] **Branch List (Screen 44)**: Name, Address, Phone, Is Active, Created At
- [ ] **Add Branch Form (Screen 45)**: Name (max 100), Address (max 255), Phone (max 20)
- [ ] **Edit/Deactivate Branch (Screen 46)**: sửa thông tin hoặc set Inactive
- [ ] Chỉ **ssadmin** truy cập (SRS §3.1.3)

### A2. Central Settings (Screen 24) — Web Admin (ssadmin only)
- [ ] Key-value config: VAT_RATE, LOYALTY_POINTS_RATE, LOYALTY_MAX_REDEMPTION_PERCENT, MAX_ACTIVE_BRANCHES, HQ_MFA_REQUIRED, CANCEL_REFUND_ALERT_THRESHOLD, etc.
- [ ] Chỉ **ssadmin** sửa

### A3. Dashboard (Screen 9) — Web Admin
- [ ] Hiển thị cho 3 HQ role (mỗi role thấy widget khác nhau)
- [ ] `ceoviewer`: tổng quan doanh thu, so sánh branch

### A4. Stock List — POS App (storemanager only)
- [ ] Danh sách stock items: Material Name, Unit, Current Qty, Min Alert Threshold
- [ ] Hiển thị low-stock badge khi qty < threshold

### A5. Stock Import/Export/Audit Forms — POS App
- [ ] **Import (Screen 27)**: chọn material, nhập qty, reason
- [ ] **Export (Screen 28)**: chọn material, nhập qty, reason (wastage/damage/etc)
- [ ] **Audit (Screen 29)**: nhập qty thực tế, tính discrepancy

### A6. Staff Schedule — POS App (storemanager only)
- [ ] Calendar view (Screen 30): xem lịch theo ngày/tuần
- [ ] Add/Edit Shift: Employee (dropdown), Date, Shift Type (MORNING/AFTERNOON/FULL_DAY), POS Register ID
- [ ] Attendance Report (Screen 31): check-in/out logs, late minutes

### A7. Reports — Web Admin
- [ ] **HQ Consolidated (Screen 23)**: doanh thu toàn chuỗi, so sánh branch, best-sellers
- [ ] **Store Revenue (Screen 32)**: doanh thu từng chi nhánh
- [ ] **COGS Report**: margin per item, shrinkage
- [ ] **Z-Report**: consolidated daily by business-day
- [ ] **Change History**: audit trail giá + voucher
- [ ] **Access Review**: current HQ accounts + change log
- [ ] **Loyalty Liability**: outstanding points + movement
- [ ] **Labour Hours**: worked-hours vs revenue
- [ ] **Anomaly Report**: per-cashier void/refund flags

## B. Checklist Tính năng

### B1. UC-63/64/65 Branch Management
| # | Test Case | Kết quả | Ghi chú |
|---|---|---|---|
| 1 | **UC-63**: Xem danh sách branch, status active/inactive | | |
| 2 | **UC-64**: Tạo branch — validate name, address, phone | | |
| 3 | UC-64: `MAX_ACTIVE_BRANCHES` limit (BR-54) | | |
| 4 | **UC-65**: Sửa branch info | | |
| 5 | UC-65: Deactivate branch → cascade: disable users, cancel schedules, notify staff (BR-55/56/57) | | |
| 6 | UC-65: Không deactivate nếu còn order PENDING/PREPARING/HOLD/READY (BR-55) | | |

### B2. UC-30/42 System Configuration
| # | Test Case | Kết quả | Ghi chú |
|---|---|---|---|
| 1 | **UC-30**: ssadmin sửa central config (VAT_RATE, LOYALTY_POINTS_RATE, etc.) | | |
| 2 | UC-30: VietQR credentials config | | |
| 3 | **UC-42**: storemanager sửa local branch settings (timezone, hardware, receipt logo) | | |
| 4 | UC-42: ssadmin KHÔNG sửa local branch settings (BR-47) | | |

### B3. UC-31/32/33/34/61 Inventory
| # | Test Case | Kết quả | Ghi chú |
|---|---|---|---|
| 1 | **UC-31**: Xem stock list branch — material name, qty, unit, low-stock flag | | |
| 2 | **UC-32**: Import stock — chọn material (dropdown từ Raw Material Master), nhập qty, reason | | |
| 3 | UC-32: `STOCK_TRANSACTION` record: type=IMPORT, qty, reason, manager_id | | |
| 4 | UC-32: `STOCK_ITEM.current_quantity` tăng đúng | | |
| 5 | **UC-33**: Export stock — qty, reason (wastage/damage) | | |
| 6 | UC-33: `current_quantity` giảm đúng, không cho xuống âm? | | |
| 7 | **UC-34**: Audit — nhập qty thực tế, tính discrepancy, reconcile | | |
| 8 | UC-34: `STOCK_TRANSACTION` type=AUDIT_ADJUSTMENT | | |
| 9 | **UC-61**: Xem import/export history — filter theo date, material | | |
| 10 | Low-stock alert: qty < `min_alert_threshold` → badge + nightly email 22:00 | | |

### B4. UC-35/36/37/38/39/66/80 Staff Management
| # | Test Case | Kết quả | Ghi chú |
|---|---|---|---|
| 1 | **UC-35**: Xem staff schedule calendar | | |
| 2 | **UC-36**: Tạo schedule — employee, date, shift type (MORNING/AFTERNOON/FULL_DAY) | | |
| 3 | **UC-37**: Sửa schedule — không sửa lịch quá khứ (BR-36) | | |
| 4 | **UC-38**: Xóa schedule — thông báo nhân viên (BR-37) | | |
| 5 | **UC-39**: Xem attendance report — check-in/out, lateness_minutes | | |
| 6 | Attendance model: 1 dòng gộp check_in_at + check_out_at (code model, A43) | | |
| 7 | **UC-66**: Xem danh sách nhân viên branch — tên, role, liên lạc | | |
| 8 | **UC-80**: Export worked-hours — CSV/PDF (A40) | | |
| 9 | UC-80: Pair CHECK_IN/CHECK_OUT, tính tổng giờ, flag missing checkouts | | |

### B5. UC-28/29/76/77/78/79/81/82/83 Reports
| # | Test Case | Kết quả | Ghi chú |
|---|---|---|---|
| 1 | **UC-28**: HQ Consolidated — doanh thu toàn chuỗi, so sánh branch, best-seller | | |
| 2 | **UC-29**: Export HQ reports — download file | | |
| 3 | **UC-76**: COGS/Margin — price − standard_cost, shrinkage per branch (BR-66) | | |
| 4 | **UC-77**: Price & Voucher Change History — audit trail from AUDIT_LOG (BR-68) | | |
| 5 | **UC-78**: Loyalty Liability — outstanding points (report bằng ĐIỂM, không VND — BR-75) | | |
| 6 | UC-78: Movement: issued/redeemed/expired per period | | |
| 7 | **UC-79**: Labour Hours vs Revenue — hours/1M VND, VND/hour (BR-76) | | |
| 8 | UC-79: ceoviewer xem chain-wide, storemanager xem own branch | | |
| 9 | **UC-81**: Z-Report — daily consolidated (gom ALL shifts, not per-shift — BR-78) | | |
| 10 | UC-81: gross/net sales, voucher/point discounts, VAT, refunds, tender breakdown | | |
| 11 | **UC-82**: Anomaly Report — per-cashier void/refund, flag outliers > `CANCEL_REFUND_ALERT_THRESHOLD` (BR-79/80) | | |
| 12 | UC-82: actor = SM (branch) + ceoviewer (chain) | | |
| 13 | **UC-83**: Access Review — current HQ accounts + account-change log from AUDIT_LOG (BR-81) | | |
| 14 | UC-40/41: Store Revenue — branch-level, export (CSV/PDF) | | |

## C. Đối chiếu Tài liệu

| Mã | Mô tả SRS/RDS | Hành vi thực tế | Khớp? | Ghi chú |
|---|---|---|---|---|
| A36 | UC-74 Raw Material Master (RDS thiếu) | | | Người 2 test, Người 5 verify dropdown Import/Export |
| A39 | UC-66 = Branch Staff List (SRS) vs Attendance Check-in (RDS) | | | RDS sai |
| A40 | Export CSV/PDF (SRS) vs Excel (RDS) | | | |
| A41 | BR-36/37: không sửa lịch quá khứ + xóa notify | | | RDS thiếu |
| A43 | Attendance: 1 dòng gộp (code) vs 1 dòng/sự kiện (SRS) | | | Code = chuẩn |
| A45 | Ảnh check-in: cron 90 ngày (code) vs lưu `photo_purge_at` (SRS) | | | Code = chuẩn |
| A47 | BR-35 loyalty expiry vs BR-54 branch cap (RDS dùng sai BR-35) | | | RDS sai BR-ID |
| A48 | UC-76/77/79 xoay vòng (RDS sai UC-ID) | | | |
| A49 | UC-41 Export vs Z-Report Archive (RDS) | | | |
| A51 | Loyalty Liability: điểm (SRS) vs VND (RDS) | | | SRS = chuẩn |
| A52 | Anomaly threshold: config key (SRS) vs hardcode >10% (RDS) | | | |
| A53 | Anomaly actor: SM+ceoviewer (SRS) vs ssadmin+businessadmin (RDS) | | | |
| A54 | Z-Report: gom theo business-day (SRS) vs per-shift (RDS) | | | |
| A55 | UC-42 Branch Settings: SM sở hữu (SRS BR-47) vs ssadmin (RDS) | | | |
| A56 | Deactivate branch: guard đơn chưa terminal (BR-55) | | | RDS chỉ check ca mở |
| A57 | Deactivate cascade: disable users + cancel schedules + notify (BR-56/57) | | | RDS thiếu |
| A58 | AddBranchForm.managerUserId (RDS có, SRS không) | | | SRS = chuẩn |
| | *Thêm dòng khi phát hiện sai lệch mới...* | | | |

---

# 📋 Tổng hợp: Template Báo cáo Kết quả

Mỗi người giao nộp 2 file:

## File 1: Báo cáo Bug

```
[ID] BUG-[Người]-[###]
Người test: Người [X]
App: Web Admin / POS App  
Module: [tên module]
Use Case: UC-[##]
Mức độ: Critical / Major / Minor / Cosmetic

Bước tái hiện:
  1. ...
  2. ...
  3. ...

Kết quả thực tế: ...
Kết quả mong đợi (theo SRS): ...
Business Rule liên quan: BR-[##]
Screenshot/Video: [đính kèm]
```

## File 2: Báo cáo Sai lệch Tài liệu

```
[ID] DOC-[Người]-[###]
Người phát hiện: Người [X]
Tài liệu bị sai: SRS / RDS / Cả hai
Section: §[x.x.x]
Mã reconciliation (nếu đã biết): A[##]

Mô tả SRS nói: ...
Mô tả RDS nói: ...
Code thực tế: ...
Đề xuất: Sửa SRS / Sửa RDS / Sửa Code / Cần thảo luận
```

---

# ⏱️ Timeline đề xuất

```
Ngày 1 (Setup + Đọc tài liệu):
  ├── Tạo 5 tài khoản test với role tương ứng
  ├── Mỗi người ĐỌC tài liệu SRS/RDS trong phạm vi mình
  └── Setup môi trường test (Web Admin + POS App)

Ngày 2-4 (Test độc lập):
  ├── Mỗi người test theo checklist B (tính năng)
  ├── Song song check A (giao diện) + C (đối chiếu tài liệu)
  └── Ghi bug + sai lệch tài liệu vào báo cáo

Ngày 5 (Test phụ thuộc chéo):
  ├── Người 2 tạo menu → Người 3 bán trên POS
  ├── Người 4 tạo voucher → Người 3 áp dụng tại checkout
  ├── Người 3 bán hàng → Người 5 kiểm tra báo cáo
  ├── Người 1 tạo user mới → Người 3 đăng nhập POS
  └── Người 2 thêm nguyên liệu → Người 5 kiểm tra kho

Ngày 6 (Tổng hợp + Regression):
  ├── Tổng hợp tất cả bug + sai lệch tài liệu
  ├── Phân loại: Bug code / Bug tài liệu / Feature missing
  └── Regression test các bug đã fix
```
