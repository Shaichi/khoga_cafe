# 3.13 System Configuration

This section details specifications for system settings, store branding profiles, taxation rules, invoice layouts, and local hardware connections.

---

## 3.13.1 F53 - Central System Settings / UC-30 Configure Central System Settings

### 3.13.1.1 Screen Mock-up (Desktop Landscape)
```
+---------------------------------------------------------------------------------+
| HQ Admin Portal > Central System Settings                                       |
+---------------------------------------------------------------------------------+
|  Brand Name:    [ Coffee Zone                  ]                                |
|  License Key:   [ CZ-2026-X892-K981            ] (Read-only)                    |
|  Currency:      [ VND (Vietnamese Dong)        ] (Read-only)                    |
|                                                                                 |
|  Global Tax & Invoice Settings:                                                 |
|  Default VAT:   [ 10.0         ] %                                              |
|  Header Title:  [ Welcome to Coffee Zone                                      ] |
|  Footer Message:[ Thank you! See you again.                                   ] |
|  Max Active Branches: [ 5      ]                                                |
|                                                                                 |
|  Loyalty Points Program Settings:                                               |
|  Accrual Rate:  [ 1.0          ] %   Redeem Value:  [ 100          ] VND/point  |
|  Max Redeem:    [ 50           ] %   Max Discount:  [ 100,000      ] VND/order  |
|                                                                                 |
|  Security & Fraud Settings:                                                     |
|  HQ MFA Required: [x]   Cancel/Refund Alert Threshold: [ 5.0 ] % of orders      |
|                                                                                 |
|                                                     [ Save Settings ] [ Cancel ] |
+---------------------------------------------------------------------------------+
```

#### Table 3-58: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Brand Name | Text | Yes | 100 | The name of the brand/HQ coffee shop. |
| 2 | License Key | Text | | | Software activation license key (read-only). |
| 3 | Currency | Text | | | Base currency system symbol (read-only). |
| 4 | Default VAT | Decimal | Yes | 5 | Percentage value for VAT rate calculation (0% to 20%). |
| 5 | Header Title | Text | Yes | 150 | Text printed at the top of POS receipts. |
| 6 | Footer Message | Text | Yes | 250 | Text printed at the bottom of POS receipts. |
| 7 | Max Active Branches | Number | Yes | 3 | Maximum number of active store branches allowed simultaneously. |
| 8 | Accrual Rate | Decimal | Yes | 5 | Percentage of net total payable earned as points (0% to 100%). |
| 9 | Redeem Value | Number | Yes | 6 | Cash value per point in VND (must be > 0). |
| 10 | Max Redeem | Decimal | Yes | 5 | Max percentage of order subtotal paid via points (0% to 100%). |
| 11 | Max Discount | Number | Yes | 8 | Max absolute discount amount in VND via points per order (must be >= 0). |
| 12 | HQ MFA Required | Toggle | Yes | | `HQ_MFA_REQUIRED` — when on, HQ-role logins (ceoviewer/businessadmin/ssadmin) require a second factor (BR-83). Default on. |
| 13 | Cancel/Refund Alert Threshold | Decimal | Yes | 5 | `CANCEL_REFUND_ALERT_THRESHOLD` — per-cashier cancel/refund rate (% of orders) above which the anomaly report flags the cashier (BR-79). |
| 14 | Save Settings | Button | | | Commits and saves global brand changes. |
| 15 | Cancel | Button | | | Discards edits and returns to dashboard home. |

### 3.13.1.2 Use Case Description

| Use Case ID | UC-30 | Use Case Name | Configure Central System Settings |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.1 |
| **Date** | 2026-06-03 | | |

| Field | Description |
|---|---|
| **Actor** | System Admin |
| **Description** | Configures global parameters including brand name, tax rate, receipt templates, and loyalty points configuration settings. |
| **Precondition** | System Admin is logged in. |
| **Trigger** | System Admin navigates to Central System Settings. |
| **Post-Condition** | Central configuration parameters are updated. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | System Admin | Updates the Brand Name, Default VAT, Header Title, Footer Message, Max Active Branches, Loyalty Points Program Settings (Accrual Rate, Redeem Value, Max Redeem, Max Discount), or Security & Fraud Settings (HQ MFA Required, Cancel/Refund Alert Threshold). |
| 2 | System Admin | Clicks "Save Settings". |
| 3 | Portal | Validates the input values. |
| 4 | Portal | Saves the updated configurations. |

#### Alternative Flows
##### AT1: Validation Errors
- **Trigger**: System Admin inputs invalid values.

| Sub-step | Actor | Action |
|---|---|---|
| 3.1 | Portal | If Brand Name is empty, displays message: `"Brand name cannot be empty."` |
| 3.2 | Portal | If Default VAT is not between 0 and 20, displays message: `"VAT rate must be a numeric value between 0 and 20."` |
| 3.3 | Portal | If Accrual Rate is not between 0 and 100, displays message: `"Accrual rate must be a numeric value between 0 and 100."` |
| 3.4 | Portal | If Redeem Value is not greater than 0, displays message: `"Redeem value must be a numeric value greater than 0."` |
| 3.5 | Portal | If Max Redeem is not between 0 and 100, displays message: `"Max redeem percentage must be a numeric value between 0 and 100."` |
| 3.6 | Portal | If Max Discount is not greater than or equal to 0, displays message: `"Max discount must be a numeric value greater than or equal to 0."` |
| 3.7 | Portal | If Max Active Branches is empty or not greater than 0, displays message: `"Max active branches must be a numeric value greater than 0."` |
| 3.8 | Portal | If Cancel/Refund Alert Threshold is not between 0 and 100, displays message: `"Cancel/refund alert threshold must be a numeric value between 0 and 100."` |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-45 | Default VAT rate must be between 0% and 20%. |
| BR-46 | Saving changes updates the receipt calculation engine and template layouts immediately. **VAT rate changes and loyalty config changes apply to new orders created after the save action. Orders already in progress (PENDING, PREPARING, READY) within the current shift session retain the parameters that were active when they were created.** |
| BR-94 | **Loyalty Config Parameters**: The loyalty engine must use central system parameters: `LOYALTY_ACCRUAL_PERCENTAGE` (Accrual Rate), `LOYALTY_REDEMPTION_VALUE_PER_POINT` (Redeem Value per Point, default 100 VND/point — see BR-74), `LOYALTY_MAX_REDEMPTION_PERCENT` (Max Redeem), and `LOYALTY_MAX_REDEMPTION_LIMIT` (Max Discount) for calculations at checkout. _(Renumbered from a duplicate "BR-57" which canonically denotes Employee ID Auto-Allocation.)_ |

---

## 3.13.2 F54 - Branch Local Settings / UC-42 Configure Local Branch Settings

### 3.13.2.1 Screen Mock-up (Mobile Portrait)
```
+------------------------------------+
|       Branch Local Settings        |
|                                    |
|  Branch Name                       |
|  [ Coffee Zone - District 1      ] |
|                                    |
|  Timezone                          |
|  [ Asia/Ho_Chi_Minh           ][v] |
|                                    |
|  Hotline Phone                     |
|  [ 0283930001                    ] |
|                                    |
|  Email                             |
|  [ d1@coffeezone.vn              ] |
|                                    |
|  Address                           |
|  [ 123 Nguyen Hue, District 1... ] |
|                                    |
|  Logo Image                        |
|  [ Choose File ] (logo_d1.png)     |
|  [ x Delete Logo ]                 |
|                                    |
|  Hardware Configuration:           |
|  POS Printer IP/Port:              |
|  [ 192.168.1.150                 ] |
|         [ Test POS Printer ]       |
|                                    |
|  Kitchen Label IP/Port:            |
|  [ COM3                          ] |
|      [ Test Kitchen Printer ]      |
|                                    |
|  [ Save Settings ]  [ Cancel ]     |
+------------------------------------+
```

#### Table 3-59: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Branch Name | Text | Yes | 100 | Local name for the branch. |
| 2 | Timezone | Dropdown | Yes | | Standard timezone ID for local time conversions (e.g. `Asia/Ho_Chi_Minh`). |
| 3 | Hotline Phone | Text | Yes | 12 | The local contact phone number (10-12 digits). |
| 4 | Email | Text | Yes | 100 | The local email address (must be valid email format). |
| 5 | Address | Text | Yes | 200 | The physical address of the store branch. |
| 6 | Logo Image | File | No | | Upload logo image (formats: PNG, JPG; max 2MB). |
| 7 | POS Printer | Text | No | 50 | IP Address or COM port of POS printer. |
| 8 | Test POS Printer | Button | | | Sends test print slip to verification port. |
| 9 | Kitchen Label | Text | No | 50 | IP Address or COM port of kitchen drink sticker printer. |
| 10 | Test Kitchen Printer | Button | | | Sends test print sticker to kitchen printer. |
| 11 | Save Settings | Button | | | Commits and saves branch-specific changes. |
| 12 | Cancel | Button | | | Discards edits and returns to dashboard. |

### 3.13.2.2 Use Case Description

| Use Case ID | UC-42 | Use Case Name | Configure Local Branch Settings |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | Store Manager |
| **Description** | Manages local branch contact details, timezone settings, and hardware devices. |
| **Precondition** | Store Manager is logged in. |
| **Trigger** | Store Manager navigates to Branch Local Settings. |
| **Post-Condition** | Local branch settings and device profiles are updated. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | Store Manager | Modifies local contact details, address, or printer device attributes. |
| 2 | Store Manager | Clicks "Save Settings". |
| 3 | Portal | Validates inputs (e.g. hotline length, email structure). |
| 4 | Portal | Saves the updated branch-level configurations. |

#### Alternative Flows
##### AT1: Validation Errors
- **Trigger**: Store Manager inputs invalid contact info.

| Sub-step | Actor | Action |
|---|---|---|
| 3.1 | Portal | If Hotline is not 10-12 digits, displays message: `"Please enter a valid store hotline number."` |
| 3.2 | Portal | If Branch Name or Address is empty, displays message: `"Store name and address cannot be empty."` |
| 3.3 | Portal | If Email is invalid, displays message: `"Please enter a valid email address."` |

##### AT2: Hardware Connection Test
- **Trigger**: Store Manager clicks connection test.

| Sub-step | Actor | Action |
|---|---|---|
| 1 | Store Manager | Clicks "Test POS Printer" or "Test Kitchen Printer". |
| 2 | Portal | Sends print packet command to the configured IP/COM port. |
| 3 | Portal | If connection is successful, device prints slip: `"PRINTER CONNECTION OK"`. |
| 4 | Portal | If connection fails, displays message: `"Unable to connect to printer at [IP/Port]. Please check device power and connection."` |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-47 | Store Managers configure their own branch's local operational settings (timezone, hardware, logo) via UC-42 Branch Local Settings. The System Admin (`ssadmin`) does not edit branch local settings; the System Admin's branch authority is limited to the Branch Management lifecycle — create, view, and deactivate branches (UC-63 to UC-65). |
| BR-48 | Device configuration fields can accept TCP/IP addresses or Serial COM ports. |

---

## 3.13.3 Branch Management

This section specifies the branch lifecycle management functionality available exclusively to the System Admin. It covers viewing, adding, and updating/deactivating store branches.

> [!IMPORTANT]
> Branch Management is a System Admin-only function for managing the store lifecycle (create, view, deactivate). It is distinct from **UC-42 Branch Local Settings**, which allows Store Managers to configure operational parameters (timezone, hardware, logo) for their assigned branch.

---

### 3.13.3.1 F55 - View Branch List / UC-63 View Branch List

#### Screen Mock-up (Desktop Landscape)
```
+---------------------------------------------------------------------------------+
| HQ Admin Portal > Branch Management                                             |
+---------------------------------------------------------------------------------+
|  Search: [ Nguyen Du            ]         Status: [ All Statuses ] [v]          |
|                                                                                 |
|  +-----+------------------------+--------------------------+----------+-------+ |
|  | ID  | Branch Name            | Address                  | Phone    | Status| |
|  +-----+------------------------+--------------------------+----------+-------+ |
|  | 001 | Coffee Zone - Dist 1   | 123 Nguyen Hue, D1       | 02839300 | Active| |
|  | 002 | Coffee Zone - Dist 7   | 45 Nguyen Thi Thap, D7   | 02839301 | Active| |
|  | 003 | Coffee Zone - Thu Duc  | 78 Vo Van Ngan, Thu Duc   | 02839302 | Closed| |
|  +-----+------------------------+--------------------------+----------+-------+ |
|  Active: 2 / MAX_ACTIVE_BRANCHES                          [ + Add Branch ]     |
+---------------------------------------------------------------------------------+
```

#### Table 3-60: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Search | Text | No | 100 | Filter branches by name or address. |
| 2 | Status | Dropdown | No | | Filter by status: `Active`, `Inactive`, `All`. |
| 3 | Branch Grid | Grid | | | Displays branch listings including ID, name, address, phone, and status. |
| 4 | Active Counter | Label | | | Shows `Active: X / MAX_ACTIVE_BRANCHES` to indicate capacity utilization. |
| 5 | Add Branch | Button | | | Navigates to Add Branch form. Disabled when `MAX_ACTIVE_BRANCHES` active branches already exist. |

#### Use Case Description

| Use Case ID | UC-63 | Use Case Name | View Branch List |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-06-02 | | |

| Field | Description |
|---|---|
| **Actor** | System Admin |
| **Description** | Displays all registered store branches and their operational statuses. |
| **Precondition** | System Admin is logged in. |
| **Trigger** | System Admin opens the Central System Settings Screen and clicks the "Quản lý Chi nhánh" button. |
| **Post-Condition** | Complete list of branches with statuses is displayed. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | System Admin | Navigates to Branch Management. |
| 2 | Portal | Retrieves all branches from STORE table and displays grid with name, address, phone, and `is_active` status. Shows count of active branches vs. the configured maximum capacity (`MAX_ACTIVE_BRANCHES`). |
| 3 | System Admin | Optionally filters by status or searches by keyword. |

---

### 3.13.3.2 F56 - Add Branch / UC-64 Add Branch

#### Screen Mock-up (Desktop Landscape)
```
+---------------------------------------------------------------------------------+
| HQ Admin Portal > Branch Management > Add Branch                               |
+---------------------------------------------------------------------------------+
|  Branch Name:    [ Coffee Zone - Binh Thanh                                   ] |
|  Address:        [ 200 Dien Bien Phu, Binh Thanh                              ] |
|  Phone:          [ 0283930005                                                 ] |
|                                                                                 |
|                                            [ Save Branch ]       [ Cancel ]     |
+---------------------------------------------------------------------------------+
```

#### Table 3-61: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Branch Name | Text | Yes | 100 | Name of the new store branch. |
| 2 | Address | Text | Yes | 255 | Physical address of the branch. |
| 3 | Phone | Text | Yes | 20 | Branch contact phone number (10-12 digits). |
| 4 | Save Branch | Button | | | Submits details to register new branch. |
| 5 | Cancel | Button | | | Discards form and returns to Branch List. |

#### Use Case Description

| Use Case ID | UC-64 | Use Case Name | Add Branch |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-06-02 | | |

| Field | Description |
|---|---|
| **Actor** | System Admin |
| **Description** | Registers a new store branch in the system. |
| **Precondition** | System Admin is logged in. Total active branches is less than the configured maximum capacity (`MAX_ACTIVE_BRANCHES`). |
| **Trigger** | System Admin clicks "+ Add Branch" on Branch List screen. |
| **Post-Condition** | New branch is created with `is_active = true` and appears in the branch list. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | System Admin | Enters Branch Name, Address, and Phone, then clicks "Save Branch". |
| 2 | Portal | Validates inputs: name is not empty, address is not empty, phone is 10-12 digits, and branch name is unique. |
| 3 | Portal | Creates new STORE record with `is_active = true`, records `created_at` timestamp, and returns to Branch List view. Displays confirmation: `"Branch successfully created."` (MSG15). |

#### Alternative Flows
##### AT1: Maximum Branch Capacity Reached
- **Trigger**: At step 2, the number of active branches already equals the configured `MAX_ACTIVE_BRANCHES` limit.

| Sub-step | Actor | Action |
|---|---|---|
| 2.1 | Portal | Displays error message: `"Maximum branch capacity reached. Please deactivate an existing branch or increase the limit before adding a new one."` (MSG16) |

##### AT2: Validation Errors
- **Trigger**: At step 2, input validation fails.

| Sub-step | Actor | Action |
|---|---|---|
| 2.1 | Portal | If Branch Name is empty, displays message: `"Branch name cannot be empty."` |
| 2.2 | Portal | If Address is empty, displays message: `"Branch address cannot be empty."` |
| 2.3 | Portal | If Phone is not 10-12 digits, displays message: `"Please enter a valid phone number (10-12 digits)."` |
| 2.4 | Portal | If Branch Name is duplicated, displays message: `"A branch with this name already exists."` |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-54 | **Maximum Active Branch Capacity**: The system supports a dynamic number of active branches simultaneously, configured via the system parameter `MAX_ACTIVE_BRANCHES`. Deactivated branches do not count toward this limit. |

---

### 3.13.3.3 F57 - Update / Deactivate Branch / UC-65 Update / Deactivate Branch

#### Screen Mock-up (Desktop Landscape)
```
+---------------------------------------------------------------------------------+
| HQ Admin Portal > Branch Management > Edit Branch                              |
+---------------------------------------------------------------------------------+
|  Branch ID: STR-001  (Read-only)       Created: 2026-01-15 (Read-only)          |
|                                                                                 |
|  Branch Name:    [ Coffee Zone - District 1                                   ] |
|  Address:        [ 123 Nguyen Hue, District 1                                 ] |
|  Phone:          [ 0283930001                                                 ] |
|  Status:         [ Active          ] [v]                                        |
|                                                                                 |
|                                            [ Save Changes ]      [ Cancel ]     |
+---------------------------------------------------------------------------------+
```

#### Table 3-62: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Branch ID | Label | | | Unique branch identifier (read-only). |
| 2 | Created | Label | | | Branch registration date (read-only). |
| 3 | Branch Name | Text | Yes | 100 | Store branch name. |
| 4 | Address | Text | Yes | 255 | Physical address. |
| 5 | Phone | Text | Yes | 20 | Branch contact phone number (10-12 digits). |
| 6 | Status | Dropdown | Yes | | Branch status: `Active` / `Inactive`. |
| 7 | Save Changes | Button | | | Saves modifications to branch record. |
| 8 | Cancel | Button | | | Discards edits and returns to Branch List. |

#### Use Case Description

| Use Case ID | UC-65 | Use Case Name | Update / Deactivate Branch |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-06-02 | | |

| Field | Description |
|---|---|
| **Actor** | System Admin |
| **Description** | Modifies branch information or deactivates (closes) a branch, triggering cascading effects on associated staff and schedules. |
| **Precondition** | System Admin is logged in. Branch record exists. |
| **Trigger** | System Admin clicks on a branch row in the Branch List to open the edit form. |
| **Post-Condition** | Branch details are updated. If deactivated: staff accounts are disabled, future schedules are cancelled. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | System Admin | Modifies branch name, address, phone, or sets Status to `Inactive`. Clicks "Save Changes". |
| 2 | Portal | Validates inputs (same rules as Add Branch form). |
| 3 | Portal | If only contact details were changed (no status change), saves updates and returns to Branch List. |

#### Alternative Flows
##### AT1: Deactivation Cascade — Branch Closure
- **Trigger**: At step 1, System Admin sets Status from `Active` to `Inactive`.

| Sub-step | Actor | Action |
|---|---|---|
| 1.1 | Portal | Checks preconditions: verifies no `SHIFT_SESSION` with `status = OPEN` exists for this branch, and no `ORDER` in non-terminal state (`PENDING`, `PREPARING`, `HOLD`, `READY`) exists for this branch. |
| 1.2 | Portal | If preconditions fail, displays error: `"Cannot deactivate branch. Please close all active shifts and complete or cancel all pending orders first."` |
| 1.3 | Portal | If preconditions pass, displays confirmation dialog: `"Deactivating this branch will disable all staff accounts assigned to it and cancel all future scheduled shifts. This action can be reversed by reactivating the branch. Proceed?"` |
| 1.4 | System Admin | Clicks "Confirm Deactivate". |
| 1.5 | Portal | Sets `STORE.is_active = false`. |
| 1.6 | Portal | Sets `USER.is_active = false` for all users where `store_id` matches the deactivated branch. Terminates their active session tokens (BR-18). |
| 1.7 | Portal | Deletes all `STAFF_SCHEDULE` entries with `shift_date > current_date` for this branch. Sends notification alerts to affected employees (BR-37). |
| 1.8 | Portal | Returns to Branch List with confirmation message: `"Branch has been deactivated."` |

##### AT2: Reactivation
- **Trigger**: At step 1, System Admin sets Status from `Inactive` to `Active`.

| Sub-step | Actor | Action |
|---|---|---|
| 1.1 | Portal | Checks that total active branches after reactivation does not exceed `MAX_ACTIVE_BRANCHES` (BR-54). |
| 1.2 | Portal | If limit would be exceeded, displays error: `"Maximum branch capacity (MAX_ACTIVE_BRANCHES) reached. Please deactivate another branch first."` (MSG16) |
| 1.3 | Portal | If within capacity, sets `STORE.is_active = true`. |
| 1.4 | Portal | Displays info message: `"Branch reactivated. Note: Staff accounts for this branch remain inactive and must be individually reactivated by the System Admin."` |

##### AT3: Validation Errors
- **Trigger**: At step 2, input validation fails (same validation as AT2 in UC-64).

| Sub-step | Actor | Action |
|---|---|---|
| 2.1 | Portal | Displays appropriate validation error message (empty name, empty address, invalid phone, or duplicate name). |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-54 | **Maximum Active Branch Capacity**: The system supports a dynamic number of active branches simultaneously, configured via the system parameter `MAX_ACTIVE_BRANCHES`. Deactivated branches do not count toward this limit. |
| BR-55 | **Branch Deactivation Preconditions**: A branch cannot be deactivated if it has any open shift sessions (`SHIFT_SESSION.status = OPEN`) or any orders in non-terminal states (`PENDING`, `PREPARING`, `HOLD`, `READY`). All shifts must be closed and all orders must reach terminal states (`COMPLETED` or `CANCELLED`) before deactivation is permitted. |
| BR-56 | **Branch Deactivation Cascade Effects**: When a branch is deactivated: (1) All `USER` accounts with matching `store_id` are set to `is_active = false` and their session tokens are terminated (per BR-18); (2) All future `STAFF_SCHEDULE` entries (`shift_date > current_date`) for the branch are deleted and notification alerts are sent to affected employees (per BR-37); (3) Existing historical data (`ORDER`, `STOCK_ITEM`, `ATTENDANCE`, `SHIFT_SESSION`) is preserved as read-only for reporting purposes. |




