# 5. Requirement Appendix & Mapping

This section contains business rules, global requirements, common application messages, and the Feature-Actor Mapping Matrix.

---

## 5.1 Business Rules

| ID | Rule Definition |
|---|---|
| BR-01 | **Membership Point Accrual**: Customers accumulate loyalty points as a percentage of the **Net Total Payable** value of their invoice, up to a maximum points accrual limit per order (configurable via system parameters). Points are not accrued for the portion of the order covered by loyalty points redemption. |
| BR-02 | **Membership Point Redemption**: Points can be redeemed for discounts at checkout, subject to point balance validation, with a limit on the maximum percentage of the invoice value that can be paid using points, and a maximum discount amount per order (configurable via central system parameters). |
| BR-03 | **Shift Session Closing**: A cashier cannot close a shift unless all orders associated with their shift ID are marked with terminal states (`COMPLETED` or `CANCELLED`). Cashier cannot close shift if there are active order queue items pending preparation. |
| BR-04 | **Shift Discrepancy Alert**: Any cash discrepancy exceeding 100,000 VND must be flagged and automatically emailed to the Store Manager. If email delivery fails, an in-app push notification is sent to the Store Manager's dashboard as a fallback. |
| BR-05 | **Order Cancellation Rules**: Order cancellation is strictly restricted to the `PENDING` status. Once the order transitions to `PREPARING` (preparation started), the cancellation action is disabled for all users, including Cashiers and Managers. |
| BR-06 | [RESERVED / DELETED] |
| BR-07 | **Inventory Action on Cancellation**: For packaged/ready-to-serve products, stock is deducted immediately at payment checkout (UC-51). If the order is cancelled while in the `PENDING` state, these items are auto-replenished. For freshly prepared items, stock is only deducted when the order transitions to the `PREPARING` state (UC-62). If cancelled while in the `PENDING` state, no stock deduction has occurred yet, so no replenishment is needed. |
| BR-08 | **Loyalty & Voucher Rollback**: Order cancellation reverses used vouchers (restoring total and customer limits) and adjusts loyalty points (gained points are deducted, and redeemed points are refunded to the customer balance). |
| BR-09 | **Refund Authorization & Execution**: Refunds for orders in the `PENDING` status can be performed directly by the Cashier without manager approval. All refunds must occur within **7 days** of the original purchase. **Cash refunds** are paid from, and recorded against, the **currently open Shift Session** on the terminal at the moment of refund (the drawer that physically pays out) — regardless of which shift the original order belonged to — reducing that shift's expected cash for reconciliation (BR-03). If **no** shift is open at the time, a cash refund cannot be processed until a shift is opened. **Card/VietQR refunds** invoke the payment gateway's refund API and have no cash-drawer impact, so they are independent of the shift session. |
| BR-10 | **Inactive Accounts Block**: Inactive accounts must be blocked from logging into the system. |
| BR-11 | **Account Suspension**: Account suspension lasts exactly 15 minutes after 5 consecutive failed attempts. |
| BR-12 | **Force Password Change Block**: Mandatory password change flag blocks navigation to any other module. User cannot bypass the Force Password Change screen. |
| BR-13 | **Logout Session Logging**: Logout time must be logged upon termination of user session. |
| BR-14 | **Password Complexity**: New passwords must be at least 8 characters, containing at least one uppercase letter, one lowercase letter, one number, and one special character. |
| BR-15 | **Password Uniqueness**: New passwords cannot match the current password. |
| BR-16 | **OTP Validity Duration**: OTP validity duration is exactly 10 minutes. |
| BR-17 | **OTP Attempt Limit**: Maximum of 3 OTP attempts before recovery session is locked. |
| BR-18 | **Session Token Invalidation**: Password change or setting status to Inactive terminates active session tokens on all other devices immediately. |
| BR-19 | **Profile Field Scopes**: Cashiers and Baristas can only change their contact email and phone. Only the System Admin (`ssadmin`) can update administrative parameters (e.g. role, branch assignment, account status) via the User Account Management tools. |
| BR-20 | **User List Pagination**: User accounts list supports pagination (default: 20 records per page). |
| BR-21 | **Activity History Scope**: Activity history displays the last 50 logins, shift history, and changes made by the user. |
| BR-22 | **Default Active Status**: Created accounts default status to active, and force a password change on next login. |
| BR-23 | **Last System Admin Account Protection**: System must block any attempt to deactivate or change the role of the last active System Admin (`ssadmin`) account, since `ssadmin` is the only role able to provision users and manage system access. |
| BR-24 | **Menu Items Autocomplete & Filters**: Items list shows search autocomplete results and real-time category filtering. |
| BR-25 | **Menu Item Availability Status**: Availability states must indicate `Available` or `Out of Stock` based on active quantities or flags. |
| BR-26 | **Menu Item Abbreviation Generation**: Abbreviation is automatically created based on first letters of words in the unsignified name (e.g. "Cà phê đá" -> "cfd") and updates if name is modified. |
| BR-27 | [RESERVED / DELETED] |
| BR-28 | **Menu Items Soft Delete**: Menu items are never permanently deleted from database to preserve historical sales reports. |
| BR-29 | **Topping Pricing & Linkage**: Price can be 0 for standard options (e.g. "No Ice", "No Sugar"). Toppings can be linked globally or selectively to drinks. |
| BR-30 | **Category Sales propagation**: Category updates propagate immediately to POS sales screen catalogs. |
| BR-31 | **Category Deletion Restriction**: Cannot delete a category if it contains active menu items. A category can only be deleted if it is empty or all its items are soft-deleted. Upon deletion, any menu items previously belonging to this category will automatically become uncategorized (per BR-62). |
| BR-32 | **Audit Discrepancy Note**: Explanatory notes are mandatory if physically counted actual quantity does not match expected value. |
| BR-33 | **Cash Float Limit**: Starting cash float must be greater than or equal to zero. |
| BR-34 | **[RESERVED / DELETED]** (Previously: Real-Time Membership Tier Levels) |
| BR-35 | **Loyalty Points Expiry**: Loyalty points expire after 12 months of customer inactivity (no new transactions made by the customer). |
| BR-36 | **Past Schedules Block**: Cannot modify schedules that occurred in the past. |
| BR-37 | **Schedules Deletion Notify**: Deletion removes the shift and sends notification alerts to affected employees. |
| BR-38 | **Attendance Log Recording** (authoritative; single definition — see §3.9.4.2): Check-in and check-out times must be recorded manually via the terminal attendance popup (using a 4-digit PIN and taking a camera snapshot) at the physical branch where the action occurs. These entries are never automatically created from the POS terminal login session. At check-in, the scheduled shift start time is snapshotted (which may be empty for cross-branch walk-in employees) so lateness can be calculated historically. _(RV-C05: this is the one BR-38; the prior duplicate "PIN Verification" wording is merged here.)_ |
| BR-39 | **Lateness Computation (branch-local, derived)**: Lateness is not stored; it is derived as `max(0, recorded_at − scheduled_start)` with **both timestamps converted to the branch-local timezone** (§5.2.2) first. Check-in at/before `scheduled_start` = 0; `NULL` when `scheduled_start` is `NULL`. (RV-C03; mirrors §3.9.4.2) |
| BR-40 | **Read-Only Voucher Code**: Alphanumeric Voucher Code string value cannot be modified after saving. |
| BR-41 | **Deactivation Redemption Block**: Deactivating a voucher immediately stops all checkout redemptions. |
| BR-42 | **Voucher Percentage Discount Cap**: When `discount_type = PERCENTAGE` and `max_discount_amount` is configured, the discount amount applied at checkout is capped at this limit: `applied_discount = min(subtotal * discount_value / 100, max_discount_amount)`. |
| BR-43 | [RESERVED / DELETED] |
| BR-44 | **Reports & Metrics Scope**: Store Managers can only view and export reports scoped to their assigned branch. CEO Viewers can access and export consolidated brand reports. |
| BR-45 | **VAT Configuration Limits**: Default VAT rate must be between 0% and 20%. |
| BR-46 | **Config Sync propagation**: Saving changes updates the receipt calculation engine and template layouts immediately. |
| BR-47 | **Branch Config Scope**: Store Managers configure their own branch's local operational settings (timezone, hardware, logo) via UC-42 Branch Local Settings. The System Admin (`ssadmin`) does not edit branch local settings; the System Admin's branch authority is limited to the Branch Management lifecycle — create, view, and deactivate branches (UC-63 to UC-65). |
| BR-48 | **IP/COM Printer Port Validation**: Device configuration fields can accept TCP/IP addresses or Serial COM ports. |
| BR-49 | **Manual Points Adjustment Limitations**: Manual points adjustments require a recorded reason and are locked to Business Admin role. |
| BR-50 | **Discount Cap**: The Net Total Payable after all discounts (voucher discount and point redemption) cannot be negative. Minimum Net Total Payable is 0 VND. The system caps the combined discount value at the Gross Subtotal. |
| BR-51 | **Order Cancellation Logging**: Every order cancellation action must record the cashier's identity, timestamp, cancellation reason, and detailed notes in the `order_cancellations` log. No manager PIN or override code verification is required. |
| BR-52 | **Voucher Status Definitions**: A voucher's display status is computed dynamically: `SCHEDULED` = current date is before `Start Date`; `ACTIVE` = current date is between `Start Date` and `End Date` inclusive and voucher has not been manually deactivated; `EXPIRED` = current date is after `End Date` or voucher has been manually deactivated. |
| BR-53 | **Attendance Check-in & Check-out**: Staff check-in and check-out are performed via a dedicated attendance popup by entering a personal 4-digit PIN and taking a camera snapshot. This action is independent of the active terminal session login. |
| BR-53a | **Cross-Branch Attendance Attribution**: Every attendance log records both the employee identity and the specific branch terminal where the check-in or check-out physically occurred. Payroll reports aggregate worked hours per employee across all branches (so employees are paid for all shifts worked anywhere), whereas branch labor-cost reports attribute hours to the branch where the shift was physically worked. |
| BR-54 | **Maximum Active Branch Capacity**: The system supports a dynamic number of active branches simultaneously, configured via the system parameter `MAX_ACTIVE_BRANCHES`. Deactivated branches (`is_active = false`) do not count toward this limit. The "Add Branch" button is disabled when the limit is reached. |
| BR-55 | **Branch Deactivation Preconditions**: A branch cannot be deactivated if it has any open shift sessions (`SHIFT_SESSION.status = OPEN`) or any orders in non-terminal states (`PENDING`, `PREPARING`, `HOLD`, `READY`). All shifts must be closed and all orders must reach terminal states (`COMPLETED` or `CANCELLED`) before deactivation is permitted. |
| BR-56 | **Branch Deactivation Cascade Effects**: When a branch is deactivated: (1) All staff accounts registered at that branch are deactivated and their active login sessions are terminated (per BR-18); (2) All future scheduled shifts for the branch are deleted, and affected employees are notified automatically (per BR-37); (3) Existing historical records (orders, local stock inventory, attendance logs, shift history) are preserved as read-only for reporting and auditing. |
| BR-57 | **Employee ID Auto-Allocation**: When creating a new employee, the system must automatically allocate a unique sequential Employee ID with the format `EMP-{Sequence}` (e.g. `EMP-043` for the 43rd employee record). |
| BR-58 | **Real-time Username Generation**: The system must automatically generate a proposed username when the System Admin enters the employee's full name. The generation algorithm uses the formula: `[Normalized Main Name in Lowercase][Initials of Middle & Family Names][Clean Sequence ID]`. Vietnamese characters must be converted to plain English alphabet. E.g. "Nguyễn Văn An" with sequence ID 43 -> "AnNV43". |
| BR-59 | **Branch Staff Isolation & Read-Only**: A Store Manager can only view, search, and call their local staff. All mutation capabilities (create, modify role, deactivate user, update PIN) are restricted to the System Admin (`ssadmin`). A Store Manager must not be allowed to view rosters or contact details of staff registered at other branch facilities. |
| BR-60 | **User Session / Shift Session Independence**: Terminating a cashier's User Session does not close the active Shift Session on the POS terminal. The Shift Session persists until explicitly closed by a cashier (UC-53) and approved by the Store Manager. |
| BR-61 | **KDS KPI Aggregation Scope**: Barista performance indicators (average preparation time, orders completed per shift) are calculated at the `store_id + shift_session_id` level. No per-barista per-drink metric is recorded. |
| BR-62 | **Category Soft-Delete Handling**: When a category is soft-deleted/archived, all menu items belonging to it have their category association removed (become uncategorized) to preserve historical sales data and prevent catalog issues. Uncategorized items appear as "Uncategorized" in the POS catalogs. |
| BR-63 | **Raw Material Master Ownership**: The raw-material catalog is chain-wide and maintained exclusively by the `businessadmin` (UC-74). Branch `STOCK_ITEM` records reference a master material by foreign key; Store Managers may transact quantities (UC-32/33/34) but cannot create, rename, or delete material types. There is no central warehouse — branches import directly from third-party suppliers. |
| BR-64 | **Raw Material Soft-Delete**: Raw materials are never hard-deleted — they are set `Inactive` to preserve recipe links and historical stock transactions. An inactive material is hidden from new recipe and import selections but remains visible in history and existing branch stock. |
| BR-65 | **Topping Recipe & Deduction**: A topping/option may carry its own recipe (`RECIPE_ITEM` via `option_topping_id` → `RAW_MATERIAL`). UC-62 deducts the recipes of the base item **and** every selected topping at `PREPARING`. Only material-free options (e.g. "No Ice") may have an empty recipe. (§3.3.6) |
| BR-66 | **Standard-Cost COGS**: Each `RAW_MATERIAL` carries a chain-wide `standard_cost` (per master unit), maintained by `businessadmin`. Item/topping cost = Σ(recipe qty × standard_cost); gross margin = price − cost. Standard cost (not per-branch purchase price) is the single basis for chain-wide COGS, margin, and ingredient-shrinkage reporting. (§3.5.0, §3.12.4) |
| BR-67 | **Store-Manager Refund/Comp (post-PENDING)**: Orders past `PENDING` cannot be cancelled (BR-05) but may be refunded or comped with **Store Manager authorisation** (SM login or PIN), logged in `ORDER_REFUND` with the approving `sm_id`. Cash refunds debit the currently-open shift drawer (BR-09); card/VietQR via gateway. Refund reverses loyalty per BR-08; partial/line-item refunds allowed; Comp/Remake re-enters the prep queue (UC-62). Original prep/sales history preserved. (UC-75, §3.7.5a) |
| BR-68 | **Mandatory Audit Log for Price & Voucher Changes**: As `businessadmin` has unilateral CRUD on selling price and vouchers (no maker-checker), every menu price change and every voucher create/update/delete is written to the immutable `AUDIT_LOG` (actor, timestamp, before/after) and surfaced read-only to `ceoviewer` via UC-77. (§3.12.5) |
| BR-69 | **Loyalty Accrual Base ("Net Total Payable")**: The loyalty accrual base is the **Net Total Payable** — the VAT-**inclusive** amount actually collected, computed *after* voucher discount and *after* loyalty-point redemption (Gross Subtotal − voucher − point redemption, floored at 0 per BR-50). It includes toppings/option modifiers (part of Gross Subtotal) and the VAT portion, but excludes the value covered by redeemed points (BR-01). This single definition governs accrual everywhere (§3.6.6.3 step 6, §3.10.4). |
| BR-70 | **Discount & Tax Stacking Order**: At checkout, calculations are applied in a fixed sequence: (1) Gross Subtotal → (2) Voucher discount → (3) Loyalty-point redemption (with %/absolute caps) → (4) VAT extraction (inclusive) → (5) accrual on Net Total Payable. Voucher and point redemption may stack (≤1 voucher per order); the combined discount is capped at Gross Subtotal so Net Total Payable ≥ 0 (BR-50). Authoritative procedure: §3.6.6.3. |
| BR-71 | **Customer PII Consent (PDPA / Decree 13/2023)**: Enrolling a customer requires recorded consent to process their personal data (phone, optional email, purchase history) for the loyalty program; the system stamps `consent_at` and `consent_version` on the `CUSTOMER` record at registration (UC-25). Consent may be withdrawn, triggering BR-72. (§3.8, §4.2.6.1) |
| BR-72 | **Personal Data Retention & Erasure**: Customer PII is retained **24 months from the last transaction**, then irreversibly anonymised (PII hashed/nulled; aggregate sales history kept). Attendance camera snapshots are auto-deleted **90 days** after capture (`photo_purge_at`), the attendance row preserved for payroll. The system supports on-request data-subject erasure ahead of the window, detaching PII from the 5-year financial records rather than deleting the transaction. (§3.8, §3.9, §4.2.6) |
| BR-73 | **Recipe Unit Consistency**: Every recipe line (base item via UC-18/19 and topping via §3.3.6) must use the **exact master stock-keeping unit** of the referenced `RAW_MATERIAL`; no kg↔g / l↔ml conversion is performed and a mismatched unit is rejected at save. Guarantees stock deduction (UC-62) and standard-cost COGS (BR-66) operate on like units. (§3.3, §3.5) |
| BR-74 | **Loyalty Redemption Value & Rounding**: The point-to-cash conversion is the parameter `LOYALTY_REDEMPTION_VALUE_PER_POINT` (default **100 VND/point**, Central System Settings / UC-30). Redeemed points must be a whole **multiple of 100** (MSG14); the raw discount `points × value` is **floored to the nearest whole VND** before the %/absolute caps (§3.6.6.3 step 3). Single definition used by checkout and the loyalty-liability report (UC-78). (§3.6.5, §3.13) |
| BR-75 | **Loyalty Liability Reporting**: Outstanding loyalty liability = **sum of all customers' current point balances** (neither redeemed nor expired per BR-35), reported in **points** (not VND). The movement table reconciles `Opening + Issued − Redeemed − Expired = Closing` for the period (issuance per BR-01/BR-69, redemption per BR-02/BR-74, expiry per BR-35). Surfaced read-only to `ceoviewer` via UC-78. (§3.12.6) |
| BR-76 | **Labour Productivity Metric (non-monetary)**: Labour efficiency is reported as **Labour Hours vs Net Sales** (`Hours per 1,000,000 VND` and `Net Sales per Labour Hour`) using worked hours (BR-77) and Net Sales (BR-69). The system stores no wage or salary rates and does not calculate financial labor costs; payroll processing remains external (§1.2). Branch labor hours are attributed to the branch where the shift was physically worked (BR-53a). Visible to CEO Viewer (chain) and Store Manager (own branch) via UC-79. (§3.12.7) |
| BR-77 | **Worked-Hours Computation**: For each employee, worked hours are calculated per business day as the sum of all paired check-in and check-out durations. Any incomplete attendance entry (missing check-in or check-out) is flagged for manager review and excluded from calculations. The system aggregates worked hours per employee to support payroll processing (BR-53a), but does not perform currency-based wage calculations (§1.2). The reports can be exported by the Store Manager to feed external payroll systems. (§3.9.6) |
| BR-78 | **Daily Z-Report Composition**: The Z-report aggregates **all shift sessions** of one branch for one business day (branch-local) into Gross Sales, Voucher Discounts, Point Redemptions, Net Sales (BR-69), VAT (inclusive 10/110), Refunds (`ORDER_REFUND`, BR-67), tender breakdown (cash/card/VietQR), and counters (orders completed, refunds, PENDING cancellations). Read-only; reconciles to the day's Close-Shift reports (UC-53). Store Manager via UC-81. (§3.12.8) |
| BR-79 | **Cancellation & Refund Anomaly Monitoring**: The system tracks, per cashier per period, the count/value of cancellations (BR-51), refunds (BR-67), vouchers applied and comps (BR-80), and flags any cashier whose cancel/refund rate exceeds the configurable `CANCEL_REFUND_ALERT_THRESHOLD`. Surfaced to Store Manager (own branch) + CEO Viewer (chain) via UC-82. Detective control only — does not block (PENDING cancel stays no-PIN per BR-05; refunds stay SM-authorised per BR-67). (§3.12.9, RV-S01) |
| BR-80 | **Checkout Discount Audit**: Every voucher application and every loyalty-point redemption at checkout writes an immutable `AUDIT_LOG` entry (`cashier_id`, `order_id`, timestamp, voucher code / redeemed points, discount amount). Closes the gap where `order_cancellations` was the only POS-side audit; feeds UC-82. (§3.6.6.3, RV-S02) |
| BR-81 | **User Account Change Audit & Access Review**: Account create (UC-11), role/status change or deactivation (UC-12/14), and credential/PIN reset write an immutable `AUDIT_LOG` entry (actor `ssadmin_id`, target, before/after role+status, timestamp). With no maker-checker on provisioning (consistent with BR-68), this audit + the periodic **Access Review report** (UC-83, read-only to `ceoviewer`) is the SoD compensating control. (§3.2.12/3.2.15, RV-S03) |
| BR-82 | **Privilege Bootstrap & Self-Escalation Prevention**: (a) The first `ssadmin` is provisioned via a secure one-time install/seed process, never the in-app UI; (b) no user may change their own role/permissions/active status — such changes require a *different* `ssadmin`; (c) all changes audit-logged (BR-81). Extends last-admin protection (BR-23). (§3.2.13, RV-S04) |
| BR-83 | **Mandatory MFA for HQ Roles**: Login by `ceoviewer` / `businessadmin` / `ssadmin` requires a second factor after password — 6-digit email OTP (reusing UC-03/04 infra) or TOTP — governed by `HQ_MFA_REQUIRED` (default true). Branch/POS roles are exempt to avoid disrupting shared-terminal operations. Three failed MFA attempts trigger the BR-17 lockout. (§3.2.1/3.2.14, RV-S05) |
| BR-84 | **VietQR Settlement Idempotency & Auto-Confirm**: A VietQR request is bound to its `order_id`; the gateway settles **at most once per `order_id`** (auto-confirmed on callback — the 60s timeout is only the error fallback). "RETRY QR" voids the prior QR and reissues for the same order; any duplicate settlement is auto-flagged for refund (BR-85), so a retry never double-charges. (§3.6.6, RV-O02/O06) |
| BR-85 | **VietQR Late-Callback Reconciliation**: A settlement callback for an already-cancelled / timed-out `order_id` does **not** revive the order; funds go to a payment-reconciliation queue, are flagged for refund, and surfaced to the Store Manager. No order is silently resurrected and no money lands unreconciled on a void order. (§3.6.6, RV-O01) |
| BR-86 | [RESERVED / DELETED] |
| BR-87 | [RESERVED / DELETED] |
| BR-88 | **READY Order Auto-Abandon & Shift Close**: A `READY` order uncollected beyond `READY_ABANDON_TIMEOUT` auto-transitions to terminal state `ABANDONED`; at shift close the Store Manager may force-close remaining `READY` orders to `ABANDONED` (logged). Stock was deducted at `PREPARING` (BR-07) so no reversal; abandoned orders are reported as uncollected and excluded from net sales. (§3.7, RV-O03) |
| BR-89 | **Negative-Stock / Phantom-Usage Ledger**: When a deduction exceeds the available balance, the system records the full deduction and lets the `STOCK_ITEM` balance go **negative**, logging the shortfall as a `phantom_usage` transaction (never clamped to 0). Negative balances surface in MSG07 and the COGS/shrinkage report (UC-76) so loss signals are auditable. (§3.5.6, RV-O16) |
| BR-90 | **Cross-Branch Shift Assignment**: A Store Manager may assign an own-branch employee to a shift at another branch directly (no host approval) via UC-36. The assignment is audit-logged (capturing the employee, home and target branches, assigning manager, and date) and makes the borrowed employee visible to the host Store Manager for that shift's duration (BR-59 exception). Worked hours follow the employee for payroll, and branch labor costs are attributed to the branch where the shift was physically worked (BR-53a). (§3.9.1, RV-C04) |
| BR-91 | **Absence & OT / Early-Leave Derivation**: From scheduled shifts vs `attendance_logs`, the system derives per employee per day: Absence (scheduled, no `CHECK_IN`), Overtime (worked beyond scheduled length), Early-Leave (`CHECK_OUT` before scheduled end). Non-monetary flags surfaced on attendance/worked-hours reports (UC-67/UC-80); no in-system leave-request workflow this release. (§3.9, RV-C06) |
| BR-92 | **Labour Budget & Working-Time Validation**: At scheduling (UC-36) the system enforces `MAX_DAILY_HOURS`, `MAX_WEEKLY_HOURS`, `MIN_REST_HOURS` (hard blocks) and a per-branch `LABOUR_HOUR_BUDGET` per period (soft, override-with-reason logged). (§3.9.1, RV-C07) |
| BR-93 | **Attendance PIN Uniqueness & Mandatory Photo**: An attendance PIN must be unique within its branch and is locked after a configurable number of failed entries. The camera snapshot is mandatory at check-in/out; if the camera is unavailable, the action is queued and flagged for Store Manager confirmation rather than recorded without a photo — closing the buddy-punching gap. (§3.9.4, RV-C08) |
| BR-94 | **Loyalty Config Parameters**: The loyalty engine uses central system parameters `LOYALTY_ACCRUAL_PERCENTAGE`, `LOYALTY_REDEMPTION_VALUE_PER_POINT` (default 100 VND/point, BR-74), `LOYALTY_MAX_REDEMPTION_PERCENT`, and `LOYALTY_MAX_REDEMPTION_LIMIT` for checkout calculations. (§3.13.1) _(Was mis-numbered "BR-57" in §3.13, which collided with Employee ID Auto-Allocation — renumbered here.)_ |
## 5.2 Common Requirements

### 5.2.1 Audit Logging
- **Rule**: All modifications to crucial records (user accounts, stock levels, tax rates, menu prices) must log an audit entry.
- **Audit Format**: `Timestamp`, `User ID`, `Action Type` (`CREATE`, `UPDATE`, `DELETE`), `Entity affected`, `Old Value JSON`, `New Value JSON`.

### 5.2.2 Datetime Formatting
- **Standard**: All date and time data must be recorded in UTC, but displayed in the store's configured local timezone (e.g., `Asia/Ho_Chi_Minh` - UTC+7) on all POS screens, reports, and invoices.

---

## 5.3 Application Messages List

The table below lists the standardized messages. 

> [!NOTE]
> **Localization & Central Management**: The message list is centrally managed via a dedicated translation dictionary (e.g., i18n JSON files). Application messages are referenced in code by their `Message Code` to allow dynamic localization and easier updates without requiring application recompilation.

| # | Message code | Message Type | Context | Content |
|---|---|---|---|---|
| 1 | MSG01 | Toast message | Authenticating employee entry successfully | *Login successful. Welcome back, {full_name}!* |
| 2 | MSG02 | In red, under the text box | Entering incorrect password or username on login | *Incorrect username or password. Remaining attempts: {count}.* |
| 3 | MSG03 | Dialog pop-up | Authenticating a suspended or deactivated account | *Account suspended. Please contact your administrator.* |
| 4 | MSG04 | Dialog pop-up | Session token expires or is cleared from client storage | *Session expired. Please login again.* |
| 5 | MSG05 | Toast message | Creating and registering a new product item successfully | *New item successfully added to menu.* |
| 6 | MSG06 | Toast message | Completing checkout transaction successfully | *Transaction completed. Change due: {amount}.* |
| 7 | MSG07 | Notification badge | Stock level of raw material falls below safety threshold | *Warning: Stock level for {item} is below safety threshold.* |
| 8 | MSG08 | Dialog pop-up | User attempts to access a restricted screen or feature | *Unauthorized action. You do not have permission to access this page.* |
| 9 | MSG09 | In red / Toast message | Voucher code input is invalid, expired, or doesn't meet minimum order value | *Voucher code is invalid or has expired.* |
| 10 | MSG10 | In red / Toast message | Entering incorrect or expired OTP recovery code | *Incorrect or expired OTP. Please check your email and try again.* |
| 11 | MSG11 | Toast message / Pop-up | Customer doesn't have enough loyalty points to redeem | *Insufficient points balance.* |
| 12 | MSG12 | Toast message / Pop-up | Assigning employee to a shift that conflicts with their existing scheduled shifts | *Employee shift conflict. The employee is already scheduled for another shift during this time block.* |
| 13 | MSG13 | [RESERVED / DELETED] | *[Reserved for future use]* | *[Reserved for future use]* |
| 14 | MSG14 | In red / Toast message | Entering points value that is not a multiple of 100 | *Redemption points must be in multiples of 100.* |
| 15 | MSG15 | Toast message | System Admin successfully creates a new branch | *Branch successfully created.* |
| 16 | MSG16 | Dialog pop-up | System Admin attempts to add a branch when maximum configured capacity is reached | *Maximum branch capacity reached. Please deactivate an existing branch or increase the limit before adding a new one.* |
| 17 | MSG17 | Dialog pop-up | Cashier attempts to log out with an active open shift | *You have an active shift session open. You must close your shift (UC-53) before logging out.* |


---

## 5.4 Feature-Actor Mapping Matrix

The matrix below maps operational modules and system features to employee roles, defining their precise access permissions.

### Access Level Legend:
- **C**: Create
- **R**: Read
- **U**: Update
- **D**: Delete
- **—**: No Access (Unauthorized)

> **HQ role split**: The former single "HQ Admin" column is now three columns per the §3.2.0 RBAC model — **CEO Viewer** (`ceoviewer`, read-only HQ reports), **Business Admin** (`businessadmin`, catalog/category/voucher/CRM), and **System Admin** (`ssadmin`, users/config/branches). Branch inventory is owned solely by the Store Manager — no HQ role has stock access (per the §3.1 Screen Authorization note).

| Feature / Functional Module | CEO Viewer | Business Admin | System Admin | Store Manager | POS Cashier | Barista |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| **User Account Management (CRUD)** | — | — | C / R / U / D | — | — | — |
| **Branch Staff Profile List** | — | — | — | R (Read-Only) | — | — |
| **Catalog Menu & Category (CRUD)** | — | C / R / U / D | — | R (Read-Only) | R (Read-Only) | R (Read-Only) |
| **Raw Material Master (chain-wide)** | — | C / R / U / D | — | R (via stock dropdowns) | — | — |
| **Menu Availability Status toggle** | — | C / R / U | — | C / R / U | — | — |
| **Voucher & Campaign (CRUD)** | — | C / R / U / D | — | — | — | — |
| **Customer Loyalty Registry** | — | C / R / U / D | — | C / R / U | C / R / U | — |
| **Staff Scheduling & Shift planner** | — | — | — | C / R / U / D | R (Read-Only) | R (Read-Only) |
| **Staff Attendance Logs & Reports** | — | — | — | C / R / U | — | — |
| **Inventory Stock Management** | — | — | — | C / R / U | — | — |
| **POS Shift Session Control** | — | — | — | U (Override) | C / R / U | — |
| **POS Checkout & Invoicing** | — | — | — | U (Override) | C / R / U | — |
| **Order Refund / Comp (post-PENDING)** | — | — | — | C / R (authorise) | C / R (initiate) | — |
| **Order Prep & Kitchen Queue** | — | — | — | R (Read-Only) | R (Read-Only) | C / R / U |
| **HQ Consolidated Business Reports** | R (Read-Only) | — | — | — | — | — |
| **Branch Revenue & Sales Reports** | R (Consolidated) | — | — | C / R / U | — | — |
| **COGS / Margin & Ingredient Shrinkage Report** | R (Consolidated) | — | — | R (own branch) | — | — |
| **Price & Voucher Change History (audit)** | R (Read-Only) | — | — | — | — | — |
| **Loyalty Liability & Movement Report** | R (Read-Only) | — | — | — | — | — |
| **Labour Hours vs Revenue Report** | R (Consolidated) | — | — | R (own branch) | — | — |
| **Worked-Hours Export (payroll feed)** | — | — | — | R (own branch) | — | — |
| **Daily Z-Report (store EOD)** | — | — | — | R (own branch) | — | — |
| **Cashier Void/Refund Anomaly Report** | R (Consolidated) | — | — | R (own branch) | — | — |
| **User Account Change & Access Review** | R (Read-Only) | — | — | — | — | — |
| **Central System Configurations** | — | — | C / R / U / D | — | — | — |
| **Branch Local Settings** | — | — | — | C / R / U | — | — |
| **Branch Management (Lifecycle)** | — | — | C / R / U | — | — | — |





