# 3.10 Promotion & Campaign Management

This section details specifications for managing discount codes and promotional campaigns.

---

## 3.10.1 F47 - List Voucher / UC-20 View Vouchers List

### 3.10.1.1 Screen Mock-up (Desktop Landscape)
```
+---------------------------------------------------------------------------------+
| HQ Admin Portal > Promotions & Vouchers                                         |
+---------------------------------------------------------------------------------+
|  Filter: [ Active     ] [v]                                 [ + Add Voucher ]   |
|                                                                                 |
|  +-----+------------+---------------+------------+------------+---------------+  |
|  | ID  | Code       | Type          | Value      | Min Order  | Expiry Date   |  |
|  +-----+------------+---------------+------------+------------+---------------+  |
|  | 001 | COFFEE20   | Percentage    | 20%        | 50,000 VND | 2026-06-30    |  |
|  | 002 | WELCOME50  | Fixed Amount  | 50,000 VND | 100,000 VND| 2026-12-31    |  |
|  +-----+------------+---------------+------------+------------+---------------+  |
|  [Page 1 of 2]                                                                  |
+---------------------------------------------------------------------------------+
```

#### Table 3-51: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Filter | Dropdown | Yes | | Filters list by voucher status (`Active`, `Scheduled`, `Expired`). |
| 2 | Add Voucher | Button | | | Navigates to Add Voucher view. |
| 3 | Grid | Grid | | | Displays voucher code campaigns. |

### 3.10.1.2 Use Case Description

| Use Case ID | UC-20 | Use Case Name | View Vouchers List |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | Business Admin |
| **Description** | Lists all promotional campaigns, active codes, and loyalty discount rules. |
| **Precondition** | Business Admin is logged in. |
| **Trigger** | Business Admin opens the Promotions module. |
| **Post-Condition** | Grid list of vouchers is displayed. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | Business Admin | Opens Promotions list. |
| 2 | Portal | Retrieves active campaigns list and displays codes, types, and stats. |

---

## 3.10.2 F48 - Add Voucher / UC-21 Add Voucher

### 3.10.2.1 Screen Mock-up (Desktop Landscape)
```
+---------------------------------------------------------------------------------+
| HQ Admin Portal > Promotions & Vouchers > Add Voucher                           |
+---------------------------------------------------------------------------------+
|  Voucher Code: [ COFFEE20       ]   Discount Type: [ Percentage     ] [v]       |
|  Discount Val: [ 20             ]   Max Disc Amount: [ 30,000 VND     ]         |
|  Min Order Val: [ 50,000 VND       ]   Start Date:      [ 2026-05-24     ]      |
|  End Date:     [ 2026-06-30       ]                                             |
|  Usage Limit per Customer: [ 1  ]   Max Total Uses: [ 100             ]       |
|                                                                                 |
|  Description:                                                                   |
|  +---------------------------------------------------------------------------+  |
|  | 20% discount on coffee beverages.                                         |  |
|  +---------------------------------------------------------------------------+  |
|                                                                                 |
|                                                  [ Save Voucher ]  [ Cancel ]   |
+---------------------------------------------------------------------------------+
```

#### Table 3-52: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Voucher Code | Text | Yes | 50 | Alphanumeric code (e.g. "COFFEE20"). |
| 2 | Discount Type | Dropdown | Yes | | Discount type (`Percentage`, `Fixed Amount`). |
| 3 | Discount Val | Text | Yes | 10 | Percentage discount or flat VND value. |
| 4 | Max Disc Amount | Text | No | 15 | Maximum discount amount cap in VND. Mandatory if Discount Type = Percentage. |
| 5 | Min Order Val | Text | Yes | 15 | Minimum order subtotal threshold in VND. |
| 6 | Start Date | Date | Yes | | Validity start timestamp. |
| 7 | End Date | Date | Yes | | Validity expiration timestamp. |
| 7 | Usage Limit | Text | No | 5 | Max usages per customer profile (guest checkout blocked if set). |
| 8 | Max Total Uses | Text | No | 5 | Overall maximum total uses cap (null for unlimited). |
| 9 | Description | Text | No | 250 | Promotion description text details. |
| 10 | Save Voucher | Button | | | Saves promotional discount parameters. |
| 11 | Cancel | Button | | | Returns to list page. |

### 3.10.2.2 Use Case Description

| Use Case ID | UC-21 | Use Case Name | Add Voucher |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | Business Admin |
| **Description** | Creates a new promotional campaign or discount code. |
| **Precondition** | Business Admin is logged in. |
| **Trigger** | Business Admin clicks "+ Add Voucher" button. |
| **Post-Condition** | New voucher configuration is saved. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | Business Admin | Enters code, value, date limits, and customer usage limits. Clicks "Save Voucher". |
| 2 | Portal | Validates code uniqueness, positive values, and date ranges. |
| 3 | Portal | Saves new voucher configurations. |

#### Alternative Flows
##### AT1: Validation Errors
- **Trigger**: At step 2, code exists or values are invalid.

| Sub-step | Actor | Action |
|---|---|---|
| 2.1 | Portal | Displays error message: `"Voucher code already exists."` or `"End date must be after the start date."` or `"Discount value must be positive."` |

---

## 3.10.3 F49 - Update/Delete Voucher / UC-22, UC-23 Update & Deactivate Voucher

### 3.10.3.1 Screen Mock-up (Desktop Landscape)
```
+---------------------------------------------------------------------------------+
| HQ Admin Portal > Promotions & Vouchers > Edit Voucher                          |
+---------------------------------------------------------------------------------+
|  Voucher Code: COFFEE20 (Read-only) Discount Type: [ Percentage     ] [v]       |
|  Discount Val: [ 20             ]   Max Disc Amount: [ 30,000 VND     ]         |
|  Min Order Val: [ 50,000 VND       ]   Start Date:      [ 2026-05-24     ]      |
|  End Date:     [ 2026-06-30       ]                                             |
|  Usage Limit per Customer: [ 1  ]   Max Total Uses: [ 100             ]       |
|                                                                                 |
|                                [ Save Changes ]   [ Deactivate ]   [ Cancel ]   |
+---------------------------------------------------------------------------------+
```

#### Table 3-53: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Voucher Code | Text | | | Read-only. Alphanumeric code — cannot be modified after creation (BR-40). |
| 2 | Discount Type | Dropdown | Yes | | Discount type (`Percentage`, `Fixed Amount`). |
| 3 | Discount Val | Text | Yes | 10 | Updated percentage discount or flat VND value. |
| 4 | Max Disc Amount | Text | No | 15 | Updated maximum discount amount cap in VND. |
| 5 | Min Order Val | Text | Yes | 15 | Updated minimum order subtotal threshold in VND. |
| 6 | Start Date | Date | Yes | | Updated validity start date. |
| 7 | End Date | Date | Yes | | Updated validity expiration date. Must be after Start Date. |
| 7 | Usage Limit per Customer | Text | No | 5 | Updated max usages per customer. |
| 8 | Max Total Uses | Text | No | 5 | Updated overall maximum total uses cap. |
| 9 | Save Changes | Button | | | Saves updated voucher values. |
| 10 | Deactivate | Button | | | Immediately deactivates voucher (sets status to INACTIVE). |
| 11 | Cancel | Button | | | Returns to list page without saving. |

### 3.10.3.2 Use Case Description

| Use Case ID | UC-22 | Use Case Name | Update Voucher |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | Business Admin |
| **Description** | Modifies code parameters or deactivates campaigns. |
| **Precondition** | Voucher exists. |
| **Trigger** | Business Admin clicks edit icon on voucher row. |
| **Post-Condition** | Voucher updates are stored. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | Business Admin | Adjusts validity dates, usage limit, or values. Clicks "Save Changes" (or "Deactivate"). |
| 2 | Portal | Validates inputs. |
| 3 | Portal | Updates configuration settings (or sets active status to inactive). |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-40 | Alphanumeric Voucher Code string value cannot be modified after saving. |
| BR-41 | Deactivating a voucher immediately stops all checkout redemptions. |
| BR-42 | **Voucher Percentage Discount Cap**: When `discount_type = PERCENTAGE` and `max_discount_amount` is configured, the discount amount applied at checkout is capped at this limit: `applied_discount = min(subtotal * discount_value / 100, max_discount_amount)`. |
| BR-52 | **Voucher Status Definitions**: A voucher's display status is computed as follows: `SCHEDULED` = current date is before `Start Date`; `ACTIVE` = current date is between `Start Date` and `End Date` inclusive, and voucher is not deactivated; `EXPIRED` = current date is after `End Date` or voucher has been manually deactivated. |
| BR-68 | *(Applies — defined in §3.12.5)* Every voucher create / update / delete is written to the immutable `AUDIT_LOG` (actor, timestamp, before/after) and is reviewable by `ceoviewer` via the Price & Voucher Change History report (UC-77). |

---

## 3.10.4 Loyalty Points Program Configuration

The loyalty program parameters are managed globally by the System Admin via central configuration parameters:

- **LOYALTY_ACCRUAL_PERCENTAGE**: The percentage of the Net Total Payable value of the invoice earned as points. E.g., `LOYALTY_ACCRUAL_PERCENTAGE = 1.0%` means a customer earns 1 point for every 10,000 VND spent (10,000 * 1% = 1 pt).
- **LOYALTY_MAX_ACC_POINTS_PER_ORDER**: The maximum points limit that a customer can accrue in a single order transaction (e.g. capped at 100 points per invoice).
- **LOYALTY_MAX_REDEMPTION_PERCENTAGE**: The maximum percentage of the order subtotal that can be paid using redeemed points (e.g. customer cannot pay more than 50% of the invoice using loyalty points).
- **LOYALTY_MAX_REDEMPTION_AMOUNT_PER_ORDER**: The maximum absolute cash discount in VND that can be redeemed using points per order (e.g. capped at 100,000 VND discount).

