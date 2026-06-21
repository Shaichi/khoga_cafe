# 3.12 Dashboard & Reporting

This section details specifications for business reports views, sales analytics dashboards, and export spreadsheets.

---

## 3.12.1 F51 - HQ Revenue Dashboard / UC-28 View Consolidated Business Reports

### 3.12.1.1 Screen Mock-up (Desktop Landscape)
```
+---------------------------------------------------------------------------------+
| HQ Admin Portal > Business Reports & Analytics                                  |
+---------------------------------------------------------------------------------+
|  Date Range: [ 2026-05-01 ] to [ 2026-05-24 ]               [ Export Report ]   |
|                                                                                 |
|  Consolidated Sales Summary (VND):                                              |
|  +----------------------+----------------------+----------------------+        |
|  | Total Revenue        | Total Orders         | Avg Transaction Val  |        |
|  | 450,000,000 VND      | 12,500               | 36,000 VND           |        |
|  +----------------------+----------------------+----------------------+        |
|                                                                                 |
|  Branch Comparison:                                                             |
|  1. Branch 1: 250,000,000 VND  (6,800 orders)                                   |
|  2. Branch 2: 200,000,000 VND  (5,700 orders)                                   |
|                                                                                 |
|  Best Sellers: [1] Peach Tea (3.4k sold)  [2] Espresso (2.9k sold)              |
+---------------------------------------------------------------------------------+
```

#### Table 3-55: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Date Range | Date Picker | Yes | | Sets start and end range boundaries for search query. |
| 2 | Export Report | Button | | | Navigates to Export Report modal screen. |

### 3.12.1.2 Use Case Description

| Use Case ID | UC-28 | Use Case Name | View Consolidated Business Reports |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | CEO Viewer |
| **Description** | Accesses centralized reports aggregating data from all store branches. |
| **Precondition** | CEO Viewer is logged in. |
| **Trigger** | CEO Viewer opens the Business Reports & Analytics dashboard. |
| **Post-Condition** | Consolidated metrics charts and grids are displayed. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | CEO Viewer | Selects date range filter boundaries. |
| 2 | Portal | Retrieves sales data, computes totals, calculates averages, and displays dashboard. |

---

## 3.12.2 F52 - Export Report / UC-29, UC-41 Export Reports

### 3.12.2.1 Screen Mock-up (Desktop Landscape Modal)
```
+------------------------------------+
|           Export Report            |
|                                    |
|  Export Format:                    |
|  ( ) Excel (.xlsx)                 |
|  (x) PDF Document                  |
|  ( ) CSV Spreadsheet               |
|                                    |
|  Data Scopes:                      |
|  [ Sales Revenue Report        ][v]|
|                                    |
|       [ DOWNLOAD ]  [ CANCEL ]     |
+------------------------------------+
```

#### Table 3-56: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Export Format | Radio | Yes | | Select target file format (`Excel`, `PDF`, `CSV`). |
| 2 | Data Scopes | Dropdown | Yes | | Select target data scope (e.g. Sales, Shift discrepancy, Inventory waste). |
| 3 | Download | Button | | | Triggers generation and file download. |
| 4 | Cancel | Button | | | Closes modal window. |

### 3.12.2.2 Use Case Description

| Use Case ID | UC-29 | Use Case Name | Export HQ Reports |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | CEO Viewer, Store Manager |
| **Description** | Generates and downloads data report files. |
| **Precondition** | User has reporting privileges. |
| **Trigger** | User clicks "Export Report" button on dashboard. |
| **Post-Condition** | Report file downloads to user local storage. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | User | Selects Format and Data Scope, and clicks "Download". |
| 2 | Portal | Generates sheet details and downloads report files. |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-44 | Store Managers can only view and export reports scoped to their assigned branch. CEO Viewers can access and export consolidated brand reports. |

---

## 3.12.3 F51.1 - Store Revenue Reports / UC-40 View Store Revenue Reports

### 3.12.3.1 Screen Mock-up (Mobile Portrait)
```
+------------------------------------+
|      Store Revenue Reports         |
|                                    |
|  From: [ 2026-05-01 ]              |
|  To:   [ 2026-05-24 ]              |
|                                    |
|         [ Export Report ]          |
|                                    |
|  Local Branch Sales Summary:       |
|  - Net Revenue:                    |
|    12,450,000 VND                  |
|  - Completed Orders: 345           |
|  - Discrepancy Total: 0 VND        |
|                                    |
|  Payment Method Breakdown:         |
|  - Cash:    4,500,000 VND          |
|  - Card:    3,950,000 VND          |
|  - VietQR:  4,000,000 VND          |
|                                    |
|  [Page 1 of 1]       [ Back ]      |
+------------------------------------+
```

#### Table 3-57: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | From Date | Date Picker | Yes | | Start of the target date range for local store reports. |
| 2 | To Date | Date Picker | Yes | | End of the target date range. Must be on or after From Date. Defaults to today. |
| 3 | Export Report | Button | | | Navigates to Export Report modal screen. |

### 3.12.3.2 Use Case Description

| Use Case ID | UC-40 | Use Case Name | View Store Revenue Reports |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | Store Manager |
| **Description** | Accesses and reviews local branch revenue, cash drawer reconciliation summaries, and sales payment types. |
| **Precondition** | Store Manager is logged in. |
| **Trigger** | Store Manager navigates to local store reports panel. |
| **Post-Condition** | Local sales dashboard metrics are displayed. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | Store Manager | Selects date or date range. |
| 2 | Portal | Retrieves local shift sessions, orders, and payment records. |
| 3 | Portal | Computes totals and displays local branch sales metrics. |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-44 | Store Managers can only view and export reports scoped to their assigned branch. CEO Viewers can access and export consolidated brand reports. |

---

## 3.12.4 F51.2 - COGS / Margin & Ingredient Shrinkage Report / UC-76 View COGS & Shrinkage Report

### 3.12.4.1 Screen Mock-up (Desktop Landscape)
```
+---------------------------------------------------------------------------------+
| HQ Admin Portal > Reports > COGS / Margin & Shrinkage                            |
+---------------------------------------------------------------------------------+
|  Date Range: [ 2026-05-01 ] to [ 2026-05-31 ]  Branch: [ All v ]  [ Export ]    |
|                                                                                 |
|  Margin per Item (standard-cost COGS — BR-66):                                  |
|  +-----------------+--------+---------+----------+---------+                     |
|  | Item            | Price  | COGS    | Margin   | Margin% |                     |
|  +-----------------+--------+---------+----------+---------+                     |
|  | Espresso        | 30,000 |  8,500  |  21,500  |   72%   |                     |
|  | Peach Tea (L)   | 45,000 | 16,200  |  28,800  |   64%   |                     |
|  | Topping: Oat Milk| 10,000|  6,000  |   4,000  |   40%   |                     |
|  +-----------------+--------+---------+----------+---------+                     |
|                                                                                 |
|  Ingredient Shrinkage (theoretical vs audited @ standard cost):                 |
|  +-----------------+----------+---------+----------+-----------+                 |
|  | Material        | Theoret. | Actual  | Variance | Loss VND  |                 |
|  +-----------------+----------+---------+----------+-----------+                 |
|  | Fresh Milk (L)  |  120.0   |  131.5  |  -11.5   |  230,000  | (!)             |
|  | Coffee Beans(kg)|   18.0   |   18.4  |   -0.4   |   60,000  |                 |
|  +-----------------+----------+---------+----------+-----------+                 |
+---------------------------------------------------------------------------------+
```

#### Table 3-64: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Date Range | Date Picker | Yes | | Reporting period boundaries. |
| 2 | Branch | Dropdown | No | | Filter to a single branch or `All` (consolidated). Store Manager is locked to own branch (BR-44). |
| 3 | Export | Button | | | Exports the report via the Export Report modal (UC-29). |
| 4 | Margin per Item grid | Grid | | | Price, standard-cost COGS, gross margin and margin% per menu item / topping (BR-66). |
| 5 | Ingredient Shrinkage grid | Grid | | | Theoretical (recipe deductions) vs audited usage per material, variance valued at standard cost; abnormal variances flagged `(!)`. |

### 3.12.4.2 Use Case Description

| Use Case ID | UC-76 | Use Case Name | View COGS / Margin & Ingredient Shrinkage Report |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-06-13 | | |

| Field | Description |
|---|---|
| **Actor** | CEO Viewer (read-only); Store Manager sees own-branch scope (per BR-44) |
| **Description** | Surfaces the chain's unit economics that branch-scoped screens cannot: (a) **gross margin per menu item** = selling price − standard-cost COGS (BR-66), chain-wide and per branch; (b) **ingredient shrinkage** = theoretical consumption (recipe deductions, UC-62) vs actual usage from physical audits (UC-34), valued at standard cost, by raw material and branch. This is the consolidated path by which HQ regains chain-wide stock/cost visibility (there is no HQ stock screen — see §3.1 note). |
| **Precondition** | CEO Viewer is logged in; menu recipes and `RAW_MATERIAL.standard_cost` are populated. |
| **Trigger** | CEO Viewer opens the COGS & Shrinkage report and selects a date range. |
| **Post-Condition** | Margin and shrinkage tables are displayed; exportable via UC-29. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | CEO Viewer | Selects date range and (optionally) a branch filter. |
| 2 | Portal | Computes per-item COGS = Σ(recipe qty × standard_cost) and gross margin vs price (BR-66). |
| 3 | Portal | Computes shrinkage = (theoretical deductions − audited actual usage) × standard_cost, grouped by raw material and branch. |
| 4 | Portal | Displays margin and shrinkage tables; flags items/materials with abnormal shrinkage. |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-66 | *(Applies — defined in §3.5.0)* Standard-cost basis for COGS and margin. |

---

## 3.12.5 F51.3 - Price & Voucher Change History / UC-77 View Price & Voucher Change History

### 3.12.5.1 Screen Mock-up (Desktop Landscape)
```
+---------------------------------------------------------------------------------+
| HQ Admin Portal > Reports > Price & Voucher Change History                      |
+---------------------------------------------------------------------------------+
|  Date Range: [ 2026-05-01 ] to [ 2026-05-31 ]  Type: [ All v ]  Actor: [ All v ]|
|                                                                                 |
|  +---------------------+-----------+-------------------+-----------+-----------+ |
|  | Timestamp           | Actor     | Entity            | Old       | New       | |
|  +---------------------+-----------+-------------------+-----------+-----------+ |
|  | 2026-05-12 09:14    | biz_an    | Price: Espresso   | 28,000    | 30,000    | |
|  | 2026-05-10 16:40    | biz_an    | Voucher: SUMMER   | (created) | 20% / cap | |
|  | 2026-05-08 11:02    | biz_lan   | Voucher: TET      | active    | deleted   | |
|  +---------------------+-----------+-------------------+-----------+-----------+ |
|  [Page 1 of 8]                                                                  |
+---------------------------------------------------------------------------------+
```

#### Table 3-65: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Date Range | Date Picker | Yes | | Reporting period boundaries. |
| 2 | Type | Dropdown | No | | Filter: `Menu Price`, `Voucher`, or `All`. |
| 3 | Actor | Dropdown | No | | Filter by the `businessadmin` account that made the change. |
| 4 | Change History grid | Grid | | | Read-only `AUDIT_LOG` entries: timestamp, actor, entity, old value, new value (BR-68). Append-only; not editable. |

### 3.12.5.2 Use Case Description

| Use Case ID | UC-77 | Use Case Name | View Price & Voucher Change History |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-06-13 | | |

| Field | Description |
|---|---|
| **Actor** | CEO Viewer (read-only) |
| **Description** | A read-only audit trail of every chain-wide **menu price change** and every **voucher create / update / delete**, sourced from `AUDIT_LOG` (BR-68). Acts as the compensating control for keeping `businessadmin` as a single unilateral role (no maker-checker): the CEO can review who changed what, when, and the before/after values. |
| **Precondition** | CEO Viewer is logged in. |
| **Trigger** | CEO Viewer opens the Price & Voucher Change History report. |
| **Post-Condition** | Chronological change log is displayed and exportable (UC-29). |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | CEO Viewer | Selects date range, entity type (Menu Price / Voucher), and optional actor filter. |
| 2 | Portal | Retrieves matching `AUDIT_LOG` entries (actor, timestamp, before/after). |
| 3 | Portal | Displays the change history table. |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-68 | **Mandatory Audit Log for Price & Voucher Changes**: Because `businessadmin` has unilateral CRUD on selling price and vouchers (no second-approver workflow), every menu **price change** and every voucher **create / update / delete** must be written to the immutable `AUDIT_LOG` with the actor's `user_id`, timestamp, and before/after values. These records are surfaced read-only to `ceoviewer` via this report (UC-77). |

---

## 3.12.6 F51.4 - Loyalty Liability & Movement Report / UC-78 View Loyalty Liability & Movement Report

### 3.12.6.1 Screen Mock-up (Desktop Landscape)
```
+---------------------------------------------------------------------------------+
| HQ Admin Portal > Reports > Loyalty Points Liability & Movement                 |
+---------------------------------------------------------------------------------+
|  Period: [ 2026-05-01 ] to [ 2026-05-31 ]   Branch: [ All v ]    [ Export ]     |
|                                                                                 |
|  Outstanding Points Balance (chain, as of period end):     1,284,500 pts        |
|                                                                                 |
|  +----------------------------+-------------------+                             |
|  | Movement (selected period) |        Points     |                             |
|  +----------------------------+-------------------+                             |
|  | Opening balance            |       1,190,000   |                             |
|  | (+) Points Issued          |         210,500   |                             |
|  | (-) Points Redeemed        |         (98,000)  |                             |
|  | (-) Points Expired (BR-35) |         (18,000)  |                             |
|  | = Closing balance          |       1,284,500   |                             |
|  +----------------------------+-------------------+                             |
|                                                                                 |
|  Note: Liability is reported in POINTS only (not VND). Per-point value is set   |
|        by LOYALTY_REDEMPTION_VALUE_PER_POINT (BR-74) if a VND estimate is needed.|
+---------------------------------------------------------------------------------+
```

#### Table 3-66: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Period | Date Picker | Yes | | Movement reporting window. |
| 2 | Branch | Dropdown | No | | Filter movement by branch, or `All` (chain). Outstanding balance is chain-wide. |
| 3 | Outstanding Points Balance | Label | | | Total un-redeemed, un-expired points across all active customers at period end. |
| 4 | Movement grid | Grid | | | Opening balance, points issued, redeemed, expired (BR-35), closing balance — in points (BR-75). |
| 5 | Export | Button | | | Exports via the Export Report modal (UC-29). |

### 3.12.6.2 Use Case Description

| Use Case ID | UC-78 | Use Case Name | View Loyalty Liability & Movement Report |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-06-14 | | |

| Field | Description |
|---|---|
| **Actor** | CEO Viewer (read-only) |
| **Description** | Surfaces the chain's **outstanding loyalty-point liability** (total un-redeemed, un-expired points) plus a period **movement** breakdown (issued / redeemed / expired). Reported in **points** so the CEO can monitor whether the loyalty programme's exposure is growing; a VND estimate can be derived externally via `LOYALTY_REDEMPTION_VALUE_PER_POINT` (BR-74). |
| **Precondition** | CEO Viewer is logged in. |
| **Trigger** | CEO Viewer opens the Loyalty Liability & Movement report. |
| **Post-Condition** | Outstanding balance and movement table are displayed; exportable via UC-29. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | CEO Viewer | Selects a period and optional branch filter. |
| 2 | Portal | Computes the outstanding points balance at period end and the issued / redeemed / expired movement for the period. |
| 3 | Portal | Displays the outstanding balance and the movement table. |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-75 | **Loyalty Liability Reporting**: The outstanding loyalty liability is the **sum of all customers' current point balances** (points that are neither redeemed nor expired per BR-35), reported in **points** (not converted to VND). The movement table reconciles `Opening + Issued − Redeemed − Expired = Closing` for the selected period. Issuance follows BR-01/BR-69 (accrual), redemption follows BR-02/BR-74, expiry follows BR-35 (12-month inactivity). |

---

## 3.12.7 F51.5 - Labour Hours vs Revenue Report / UC-79 View Labour Hours vs Revenue Report

### 3.12.7.1 Screen Mock-up (Desktop Landscape)
```
+---------------------------------------------------------------------------------+
| HQ Admin Portal > Reports > Labour Hours vs Revenue                             |
+---------------------------------------------------------------------------------+
|  Period: [ 2026-05-01 ] to [ 2026-05-31 ]   Branch: [ All v ]    [ Export ]     |
|                                                                                 |
|  +-----------------+-------------+-------------+----------------+--------------+ |
|  | Branch          | Labour Hrs  | Net Sales   | Hrs / 1M VND   | VND / Hr     | |
|  +-----------------+-------------+-------------+----------------+--------------+ |
|  | District 1      |      612.5  | 248,400,000 |          2.47  |   405,551    | |
|  | Thu Duc         |      488.0  | 171,900,000 |          2.84  |   352,254    | |
|  | (Chain total)   |    1,100.5  | 420,300,000 |          2.62  |   381,917    | |
|  +-----------------+-------------+-------------+----------------+--------------+ |
|                                                                                 |
|  Note: Productivity metric only — no wage/payroll amounts (payroll is external, |
|        §1.2). Labour hours sourced from attendance worked-hours (BR-77).        |
+---------------------------------------------------------------------------------+
```

#### Table 3-67: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Period | Date Picker | Yes | | Reporting window. |
| 2 | Branch | Dropdown | No | | `All` (chain, CEO Viewer) or a single branch. A Store Manager sees only their own branch. |
| 3 | Labour Hrs | Label | | | Total worked-hours for the branch in the period (BR-77). |
| 4 | Net Sales | Label | | | Net sales (Net Total Payable summed) for the branch in the period. |
| 5 | Hrs / 1M VND | Label | | | Labour intensity = Labour Hrs ÷ (Net Sales / 1,000,000). |
| 6 | VND / Hr | Label | | | Revenue productivity = Net Sales ÷ Labour Hrs. |

### 3.12.7.2 Use Case Description

| Use Case ID | UC-79 | Use Case Name | View Labour Hours vs Revenue Report |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-06-14 | | |

| Field | Description |
|---|---|
| **Actor** | CEO Viewer (chain, read-only); Store Manager (own branch only) |
| **Description** | Relates **labour hours worked** to **revenue earned** per branch, as a staffing-efficiency KPI. Deliberately a **non-monetary** labour metric (hours, not wages) because payroll calculation is out of scope and handled by external accounting (§1.2). Lets the chain spot over/under-staffed branches relative to sales. |
| **Precondition** | Actor is logged in (CEO Viewer or Store Manager). |
| **Trigger** | Actor opens the Labour Hours vs Revenue report. |
| **Post-Condition** | Per-branch labour-intensity and revenue-productivity figures are displayed; exportable via UC-29/UC-41. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | Actor | Selects a period (and branch, if CEO Viewer). |
| 2 | Portal | Sums worked-hours (BR-77) and Net Sales per branch for the period and computes the ratios. |
| 3 | Portal | Displays the per-branch table (CEO Viewer sees all branches + chain total; Store Manager sees their branch only). |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-76 | **Labour Productivity Metric (non-monetary)**: Labour efficiency is reported as **Labour Hours vs Net Sales** — `Hours per 1,000,000 VND` and `Net Sales per Labour Hour` — using worked-hours (BR-77) and Net Sales (BR-69). The system stores **no wage/salary rate** and converts no hours to money; payroll cost remains external (§1.2). Branch labour hours are attributed by the terminal `store_id` where the shift was worked (BR-53a). |

---

## 3.12.8 F51.6 - Daily Z-Report / UC-81 View Daily Z-Report

### 3.12.8.1 Screen Mock-up (Desktop / Tablet Landscape)
```
+---------------------------------------------------------------------------------+
| Store Manager Portal > Reports > Daily Z-Report                                 |
+---------------------------------------------------------------------------------+
|  Business Day: [ 2026-05-24 ]   Branch: District 1            [ Export / Print ] |
|                                                                                 |
|  Sales                              | Tender Breakdown                          |
|  Gross Sales            58,200,000  | Cash                  21,400,000          |
|  (-) Voucher Discounts  (1,900,000) | Card                  15,800,000          |
|  (-) Point Redemptions    (640,000) | VietQR                19,820,000          |
|  = Net Sales            55,660,000  | --------------------------------          |
|  VAT (incl, 10/110)      5,060,000  | Total Collected       57,020,000          |
|  (-) Refunds            (1,360,000) |                                           |
|                                     | Orders Completed: 412   Refunds: 6        |
|  Shifts in day: 3 (all CLOSED)      | Cancellations (PENDING): 11               |
+---------------------------------------------------------------------------------+
```

#### Table 3-68: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Business Day | Date Picker | Yes | | The calendar business day (branch-local, §5.2.2) to summarise. |
| 2 | Sales block | Label group | | | Gross sales, voucher discounts, point redemptions, net sales, VAT, refunds. |
| 3 | Tender Breakdown | Label group | | | Amount collected by tender type (cash / card / VietQR) and total collected. |
| 4 | Counters | Label group | | | Orders completed, refund count, PENDING cancellation count, number of shifts. |
| 5 | Export / Print | Button | | | Exports / prints the Z-report (UC-41 / UC-29). |

### 3.12.8.2 Use Case Description

| Use Case ID | UC-81 | Use Case Name | View Daily Z-Report |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-06-14 | | |

| Field | Description |
|---|---|
| **Actor** | Store Manager (own branch) |
| **Description** | A consolidated **end-of-day** summary for one branch and one business day — aggregating **all shift sessions** in that day into a single statement of sales, discounts, VAT, refunds, and tender breakdown. Complements the per-shift Close-Shift report (UC-53) with a day/branch total the manager reconciles and the chain can audit. |
| **Precondition** | Store Manager is logged in; the business day has at least one shift session. |
| **Trigger** | Store Manager opens the Daily Z-Report for a chosen business day. |
| **Post-Condition** | The day's consolidated totals are displayed; exportable / printable. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | Store Manager | Selects a business day. |
| 2 | Portal | Aggregates every shift session of that day (branch-local) into gross sales, voucher/point discounts, net sales, VAT, refunds, and tender totals (BR-78). |
| 3 | Portal | Displays the Z-report and offers export/print. |

#### Alternative Flows
##### AT1: Open Shift in the Day
- **Trigger**: At step 2, the selected business day still has an `OPEN` shift session.

| Sub-step | Actor | Action |
|---|---|---|
| 2.1 | Portal | Displays the totals so far with a banner: `"Provisional — 1 shift still open. Figures finalise when all shifts are closed."` |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-78 | **Daily Z-Report Composition**: The Z-report aggregates **all shift sessions** of one branch for one business day (branch-local, §5.2.2) into: Gross Sales, Voucher Discounts, Point Redemptions, Net Sales (BR-69), VAT (inclusive, 10/110), Refunds (`ORDER_REFUND`, BR-67), tender breakdown (cash / card / VietQR), and counters (orders completed, refund count, PENDING cancellation count). It is read-only and reconciles to the sum of that day's Close-Shift reports (UC-53). |

---

## 3.12.9 F51.7 - Cashier Void/Refund Anomaly Report / UC-82 View Cashier Void/Refund Anomaly Report

### 3.12.9.1 Screen Mock-up (Desktop / Tablet Landscape)
```
+---------------------------------------------------------------------------------+
| Reports > Cashier Void / Refund Anomaly                                         |
+---------------------------------------------------------------------------------+
|  Period: [ 2026-05-01 ]–[ 2026-05-31 ]   Branch: [ District 1 v ]   [ Export ]  |
|                                                                                 |
|  +-----------+--------+----------+---------+----------+--------+---------------+ |
|  | Cashier   | Orders | Cancels  | Refunds | Vouchers | Comps  | Flag          | |
|  +-----------+--------+----------+---------+----------+--------+---------------+ |
|  | An (C)    |   612  |  8 (1.3%)|  3      |  41      |  2     |  -            | |
|  | Binh (C)  |   470  | 39 (8.3%)| 17      |  88      |  9     | ⚠ HIGH cancel | |
|  | Cuong (C) |   388  |  5 (1.3%)|  2      |  30      |  1     |  -            | |
|  +-----------+--------+----------+---------+----------+--------+---------------+ |
|                                                                                 |
|  ⚠ rows exceed CANCEL_REFUND_ALERT_THRESHOLD — review for void/comp abuse.      |
+---------------------------------------------------------------------------------+
```

#### Table 3-72: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Period | Date Picker | Yes | | Reporting window. |
| 2 | Branch | Dropdown | No | | Store Manager: own branch only. CEO Viewer: any branch or `All` (chain). |
| 3 | Per-cashier grid | Grid | | | Per cashier: orders, cancellations (count + % of orders), refunds, vouchers applied, comps — sourced from `order_cancellations` (BR-51), `ORDER_REFUND` (BR-67), and the checkout discount log (BR-80). |
| 4 | Flag | Indicator | | | ⚠ when a cashier's cancel or refund rate exceeds `CANCEL_REFUND_ALERT_THRESHOLD` (BR-79). |
| 5 | Export | Button | | | Exports via the Export Report modal (UC-29/UC-41). |

### 3.12.9.2 Use Case Description

| Use Case ID | UC-82 | Use Case Name | View Cashier Void/Refund Anomaly Report |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-06-14 | | |

| Field | Description |
|---|---|
| **Actor** | Store Manager (own branch); CEO Viewer (chain, read-only) |
| **Description** | Surfaces per-cashier **cancellation, refund, voucher and comp activity** so abnormal patterns (e.g. a cashier voiding cash orders or over-applying vouchers/comps for acquaintances) are visible. PENDING cancellation stays no-PIN (BR-05) and every refund already requires Store-Manager authorisation (BR-67); this report is the **detective control** that complements those, flagging outliers against a configurable threshold (BR-79). |
| **Precondition** | Actor is logged in (Store Manager or CEO Viewer). |
| **Trigger** | Actor opens the Cashier Void/Refund Anomaly report. |
| **Post-Condition** | Per-cashier activity is displayed with anomaly flags; exportable via UC-29/UC-41. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | Actor | Selects a period (and branch, if CEO Viewer). |
| 2 | Portal | Aggregates per-cashier cancellations (BR-51), refunds (BR-67), voucher/point applications and comps (BR-80) for the period. |
| 3 | Portal | Computes cancel/refund rates and flags cashiers exceeding `CANCEL_REFUND_ALERT_THRESHOLD` (BR-79). |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-79 | **Cancellation & Refund Anomaly Monitoring**: The system tracks, per cashier per period, the count and value of order cancellations (BR-51), refunds (BR-67), vouchers applied and comps (BR-80), and flags any cashier whose cancellation or refund rate exceeds the configurable parameter `CANCEL_REFUND_ALERT_THRESHOLD`. Flags are surfaced to the Store Manager (own branch) and CEO Viewer (chain) via UC-82. This is a detective control; it does not block transactions (PENDING cancel stays no-PIN per BR-05, refunds stay SM-authorised per BR-67). (RV-S01) |
| BR-80 | **Checkout Discount Audit**: Every voucher application and every loyalty-point redemption at checkout writes an immutable `AUDIT_LOG` entry with `cashier_id`, `order_id`, timestamp, voucher code / redeemed points, and discount amount. Closes the gap where `order_cancellations` was the only POS-side audit; feeds UC-82. (§3.6.6.3, RV-S02) |


