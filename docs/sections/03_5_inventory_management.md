# 3.5 Inventory & Stock Management

This section details specifications for the chain-wide raw-material master catalog, viewing inventory, managing imports/exports, and reconciling discrepancies.

> **Scope note (two layers):** The **Raw Material Master** (§3.5.0, UC-74) is a chain-wide catalog owned by the **Business Admin** at HQ — it defines *which* raw materials exist (name, unit, code). The **branch stock** screens (§3.5.1–§3.5.5) are owned by the **Store Manager** and track *quantities* of those materials per branch. There is **no central warehouse**: branches import directly from third-party suppliers (UC-32). Branches cannot create new material types — they only transact quantities of materials defined in the master.

---

## 3.5.0 F22.1 - Manage Raw Material Master / UC-74 Manage Raw Material Master

### 3.5.0.1 Screen Mock-up (Desktop Landscape)
```
+-------------------------------------------------------------+
|   Raw Material Master (Chain-wide)      [ + Add Material ]   |
|                                                             |
|  Search: [ milk                                       ]     |
|                                                             |
|  +--------+----------------------+--------+--------+------+ |
|  | Code   | Material Name        | Unit   | Min(*) | Stat | |
|  +--------+----------------------+--------+--------+------+ |
|  | STK-01 | Coffee Beans         | kg     | 5.0    | Active| |
|  | STK-02 | Fresh Milk           | liter  | 6.0    | Active| |
|  | STK-03 | Peach Syrup          | ml     | 500    | Active| |
|  +--------+----------------------+--------+--------+------+ |
|  (*) Suggested minimum threshold (default for new branches) |
+-------------------------------------------------------------+
```

#### Table 3-23a: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Search | Text | No | 50 | Filter the master list by material name or code. |
| 2 | Add Material | Button | | | Opens the Add/Edit Material form. |
| 3 | Material Code | Text | Yes | 20 | Unique chain-wide identifier (e.g. `STK-01`). Immutable after creation. |
| 4 | Material Name | Text | Yes | 100 | Display name of the raw material / ingredient. |
| 5 | Unit | Dropdown | Yes | | Unit of measure (`kg`, `liter`, `ml`, `gram`, `piece`, ...). Locked once any stock transaction references the material. |
| 6 | Suggested Minimum | Text | No | 10 | Default low-stock threshold proposed to branches (each branch may override locally). |
| 7 | Standard Cost | Decimal (Currency/VND) | No | | Standard unit cost per **Unit** (e.g. VND per kg). The chain-wide reference cost used to compute recipe COGS and gross margin (BR-66). Maintained by Business Admin; not a per-branch purchase price. |
| 8 | Status | Toggle | | | `Active` / `Inactive` (soft delete). |

### 3.5.0.2 Use Case Description

| Use Case ID | UC-74 | Use Case Name | Manage Raw Material Master |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-06-09 | | |

| Field | Description |
|---|---|
| **Actor** | Business Admin |
| **Description** | Maintains the chain-wide catalog of raw materials/ingredients (the canonical source for recipe formulations and for the item dropdowns on every branch's Import/Export Stock screens). Supports view, add, edit, and deactivate. |
| **Precondition** | Business Admin is logged in. |
| **Trigger** | Business Admin opens the Raw Material Master screen. |
| **Post-Condition** | The master catalog is updated; changes propagate to recipe selection and branch stock dropdowns. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | Business Admin | Opens Raw Material Master and reviews the existing catalog. |
| 2 | Business Admin | Clicks "+ Add Material" (or edits a row): enters Code, Name, Unit, and optional Suggested Minimum. |
| 3 | Portal | Validates that the Material Code is unique chain-wide and the unit is selected. |
| 4 | Portal | Saves the master record; it becomes selectable in recipes (§3.3) and branch Import/Export dropdowns (UC-32/33). |

#### Alternative Flows
##### AT1: Duplicate Material Code
- **Trigger**: At step 3, the entered Material Code already exists.

| Sub-step | Actor | Action |
|---|---|---|
| 3.1 | Portal | Displays error message: `"A raw material with this code already exists."` |

##### AT2: Deactivate a Referenced Material
- **Trigger**: Business Admin sets a material to `Inactive` while it is still linked to active recipes or has branch stock on hand.

| Sub-step | Actor | Action |
|---|---|---|
| 1 | Portal | Soft-deletes the material (sets `Inactive`): it is hidden from new recipe/import selections but retained for history. Displays an info notice listing the active recipes still referencing it, prompting the Business Admin to update those recipes. |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-63 | **Raw Material Master Ownership**: The raw-material catalog is chain-wide and maintained exclusively by the `businessadmin`. Branch `STOCK_ITEM` records reference a master material by foreign key; Store Managers may transact quantities (UC-32/33/34) but cannot create, rename, or delete material types. |
| BR-64 | **Raw Material Soft-Delete**: Raw materials are never hard-deleted — they are set `Inactive` to preserve recipe links and historical stock transactions. An inactive material is hidden from new recipe and import selections but remains visible in history and existing branch stock. |
| BR-66 | **Standard-Cost COGS**: Each `RAW_MATERIAL` carries a chain-wide `standard_cost` per master unit, maintained by `businessadmin`. The cost of a menu item or topping is computed as Σ(`RECIPE_ITEM.quantity_required` × `RAW_MATERIAL.standard_cost`) across its recipe lines. Gross margin = selling price − computed cost. Standard cost (not per-branch purchase price) is the single basis for chain-wide COGS, margin, and ingredient-shrinkage reporting (see §3.12). Recipe quantities must be expressed in the material's master unit. |

---

## 3.5.1 F23 - View Stock List / UC-31 View Stock List

### 3.5.1.1 Screen Mock-up (Mobile Portrait)
```
+------------------------------------+
|            Stock List              |
|                                    |
|  Search: [ CoffeeBeans           ] |
|  [x] Low Stock Only                |
|                                    |
|  - Coffee Beans (STK-01)           |
|    Qty: 1.2 kg  (Min: 5.0 kg) [LOW]|
|                                    |
|  - Fresh Milk (STK-02)             |
|    Qty: 12.0 liters  (Min: 6.0 l)  |
|                                    |
|         [ IMPORT ]    [ EXPORT ]   |
+------------------------------------+
```

#### Table 3-24: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Search | Text | No | 50 | Filter stock list by item name. |
| 2 | Low Stock Only | Checkbox | Yes | | Toggles display to only show items below alert threshold. |
| 3 | Import | Button | | | Navigates to Import Stock screen. |
| 4 | Export | Button | | | Navigates to Export Stock screen. |

### 3.5.1.2 Use Case Description

| Use Case ID | UC-31 | Use Case Name | View Stock List |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | Store Manager |
| **Description** | Displays the current physical inventory count of ingredients and store supplies. |
| **Precondition** | Store Manager is logged in and assigned to store. |
| **Trigger** | Manager navigates to Stock List view. |
| **Post-Condition** | Displays local inventory item counts and safety statuses. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | Manager | Opens the Stock List screen. |
| 2 | Portal | Displays current stock items list including quantity, unit type, threshold level, and alert flag. |

---

## 3.5.2 F24 - Import Stock / UC-32 Import Stock

### 3.5.2.1 Screen Mock-up (Desktop Landscape / Multi-line Grid)
```
+-------------------------------------------------------------+
|                        Import Stock                         |
|                                                             |
|  Supplier: [ Highlands Supplier                       ]     |
|  Invoice No: [ INV-2026-001                           ]     |
|                                                             |
|  +---------------------+------------+------------+-------+  |
|  | Item Name           | Qty        | Unit Price | Total |  |
|  +---------------------+------------+------------+-------+  |
|  | [ Coffee Beans  ][v]| [ 15.0  ]  | [ 180,000] | 2.7M  |  |
|  | [ Fresh Milk    ][v]| [ 10.0  ]  | [  25,000] | 250k  |  |
|  +---------------------+------------+------------+-------+  |
|  [ + Add Line Item ]                                        |
|                                                             |
|  Grand Total: 2,950,000 VND                                 |
|  Notes:                                                     |
|  [ Restock materials                                  ]     |
|                                                             |
|                 [ SUBMIT ]      [ CANCEL ]                  |
+-------------------------------------------------------------+
```

#### Table 3-25: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Supplier | Text | Yes | 100 | Supplier source name. |
| 2 | Invoice No | Text | No | 50 | Supplier invoice number for audit trace. |
| 3 | Import Grid | Grid | Yes | | Dynamic table of imported items containing dropdown for Item Name, text fields for Qty and Unit Price, and displaying line Totals. |
| 4 | Add Line Item | Button | | | Adds a new empty row to the Import Grid. |
| 5 | Grand Total | Label | | | Displays total calculated invoice cost dynamically. |
| 6 | Notes | Text | No | 250 | General transaction notes. |
| 7 | Submit | Button | | | Submits batch transaction and increases stock quantities. |
| 8 | Cancel | Button | | | Discards edits and returns to Stock list screen. |

### 3.5.2.2 Use Case Description

| Use Case ID | UC-32 | Use Case Name | Import Stock |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.1 |
| **Date** | 2026-06-03 | | |

| Field | Description |
|---|---|
| **Actor** | Store Manager |
| **Description** | Records incoming batch of items received from suppliers to replenish local inventory levels in a single transaction. |
| **Precondition** | Manager is logged in. |
| **Trigger** | Manager clicks "Import" button. |
| **Post-Condition** | Stock is replenished. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | Manager | Enters Supplier, Invoice No, notes, and adds line items in the Import Grid (specifying item, quantity, unit price). |
| 2 | Portal | Calculates dynamic line totals and grand total. Validates all quantities and prices are positive numbers. |
| 3 | Portal | Increments stock quantities of all listed items and records a batch transaction log. |

#### Alternative Flows
##### AT1: Validation Errors
- **Trigger**: At step 2, input checks fail.

| Sub-step | Actor | Action |
|---|---|---|
| 2.1 | Portal | Displays error message: `"Please enter positive numeric values for quantity and unit price."` |

---

## 3.5.3 F25 - Export Stock / UC-33 Export Stock

### 3.5.3.1 Screen Mock-up (Mobile Portrait)
```
+------------------------------------+
|            Export Stock            |
|                                    |
|  Item Name                         |
|  [ Fresh Milk                  ][v]|
|                                    |
|  Quantity (liters)                 |
|  [ 2.0                           ] |
|                                    |
|  Reason                            |
|  [ Damage/Spoilage             ][v]|
|                                    |
|  Notes                             |
|  [ Discarded sour milk           ] |
|                                    |
|        [ SUBMIT ]   [ CANCEL ]     |
+------------------------------------+
```

#### Table 3-26: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Item Name | Dropdown | Yes | | Scopes stock items list. |
| 2 | Quantity | Text | Yes | 10 | Decimal quantity. |
| 3 | Reason | Dropdown | Yes | | Reason (`Daily Operations Usage`, `Damage/Spoilage`, `Loss/Theft`). |
| 4 | Notes | Text | No | 250 | Optional notes. |
| 5 | Submit | Button | | | Submits export request. |
| 6 | Cancel | Button | | | Discards edits. |

### 3.5.3.2 Use Case Description

| Use Case ID | UC-33 | Use Case Name | Export Stock |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | Store Manager |
| **Description** | Records manual stock removals for internal usage or wastage disposal. |
| **Precondition** | Manager is logged in. |
| **Trigger** | Manager clicks "Export" button. |
| **Post-Condition** | Stock is reduced. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | Manager | Selects item, inputs quantity and reason, then clicks "Submit". |
| 2 | Portal | Validates quantity does not exceed current safety stock counts. |
| 3 | Portal | Decrements stock quantity and logs transaction details. |

#### Alternative Flows
##### AT1: Insufficient Stock
- **Trigger**: At step 2, quantity exceeds **current total stock** level.

| Sub-step | Actor | Action |
|---|---|---|
| 2.1 | Portal | Displays error message: `"Cannot export quantity. Current stock level is too low."` |

> **Note:** Validation checks against the item's **current total stock quantity** (not the safety threshold). The safety threshold triggers a low-stock warning (MSG07) but does not block exports.

---

## 3.5.4 F26 - View Import/Export History / UC-61 View Import/Export History

### 3.5.4.1 Screen Mock-up (Mobile Portrait)
```
+------------------------------------+
|         Stock Transactions         |
|                                    |
|  Filter: [ All Types ] [v]         |
|                                    |
|  - 2026-05-24 09:15                |
|    IMPORT: Coffee Beans (+15.0 kg) |
|                                    |
|  - 2026-05-23 18:30                |
|    EXPORT: Fresh Milk (-2.0 l)     |
|    Reason: Damage/Spoilage         |
|                                    |
|                        [ Back ]    |
+------------------------------------+
```

#### Table 3-27: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Filter | Dropdown | Yes | | Filters by transaction type (`IMPORT`, `EXPORT`, `AUDIT`). |
| 2 | Back | Button | | | Returns to Stock List screen. |

### 3.5.4.2 Use Case Description

| Use Case ID | UC-61 | Use Case Name | View Import/Export History |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | Store Manager |
| **Description** | Displays a chronological list of all stock transactions. |
| **Precondition** | Manager is logged in. |
| **Trigger** | Manager opens the transaction history log panel. |
| **Post-Condition** | Displays transaction logs. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | Manager | Opens transaction history screen. |
| 2 | Portal | Retrieves and displays stock logs list. |

---

## 3.5.5 F27 - Perform Inventory Audit / UC-34 Perform Inventory Audit

### 3.5.5.1 Screen Mock-up (Mobile Portrait)
```
+------------------------------------+
|          Inventory Audit           |
|                                    |
|  Active Item: Coffee Beans         |
|  Expected: 1.2 kg                  |
|                                    |
|  Actual Count:                     |
|  [ 1.0                           ] |
|                                    |
|  Discrepancy Notes (Mandatory if   |
|  there is a difference):           |
|  [ Spill waste during prep       ] |
|                                    |
|        [ SUBMIT ]   [ CANCEL ]     |
+------------------------------------+
```

#### Table 3-28: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Actual Count | Text | Yes | 10 | Physically counted quantity of the stock item. |
| 2 | Discrepancy Notes | Text | No | 250 | Mandatory explanation if discrepancy exists. |
| 3 | Submit | Button | | | Submits audit adjustment. |
| 4 | Cancel | Button | | | Returns to Stock list. |

### 3.5.5.2 Use Case Description

| Use Case ID | UC-34 | Use Case Name | Perform Inventory Audit |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | Store Manager |
| **Description** | Reconciles discrepancies between physical counts and system values. |
| **Precondition** | Manager is logged in. |
| **Trigger** | Manager clicks Audit for specific item. |
| **Post-Condition** | Inventory records are updated. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | Manager | Enters physically counted quantity and notes discrepancy. |
| 2 | Manager | Clicks "Submit". |
| 3 | Portal | Reconciles quantity and logs audit adjustment. |

#### Alternative Flows
##### AT1: Negative Quantity Input
- **Trigger**: At step 2, Manager enters a negative value for the actual counted quantity.

| Sub-step | Actor | Action |
|---|---|---|
| 2.1 | Portal | Displays error message: `"Actual counted quantity must be a non-negative numeric value."` |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-32 | Explanatory notes are mandatory if physically counted actual quantity does not match expected value. |

---

## 3.5.6 F27.1 - Auto-Deduct Stock on Prep Start / UC-62 Auto-Deduct Inventory on Prep Start

### 3.5.6.1 Use Case Description

| Use Case ID | UC-62 | Use Case Name | Auto-Deduct Inventory on Prep Start |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.1 |
| **Date** | 2026-06-01 | | |

| Field | Description |
|---|---|
| **Actor** | System (automated) |
| **Description** | Automatically deducts ingredient quantities from stock based on the recipe formulation of each menu item **and each selected topping** (BR-65) when an order transitions to the `PREPARING` state. |
| **Precondition** | Order status transitions from `PENDING` to `PREPARING`. Menu items in the order have linked recipe ingredient mappings. |
| **Trigger** | Barista clicks "START PREP" on the kitchen queue display, transitioning the order to `PREPARING`. |
| **Post-Condition** | Stock quantities for all associated ingredients are reduced according to each item's recipe. A stock transaction log entry of type `AUTO` is created. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | Barista | Taps "START PREP" on an order in the queue. |
| 2 | System | Retrieves the recipe formulation (ingredient quantities) for each menu item **and each topping selected** on the order's line items. |
| 3 | System | Deducts the corresponding quantities from each ingredient's stock count. |
| 4 | System | Logs each deduction as a stock transaction record (type: `AUTO`, linked to Order ID). |
| 5 | System | If any ingredient falls below the safety threshold after deduction, triggers MSG07 low-stock notification to the Store Manager. |

#### Alternative Flows
##### AT1: Ingredient Quantity Insufficient
- **Trigger**: At step 3, the required ingredient quantity exceeds the current available stock.

| Sub-step | Actor | Action |
|---|---|---|
| 3.1 | System | Records the **full recipe deduction** even if it drives the balance below zero — the `STOCK_ITEM` balance is allowed to go **negative**, and the shortfall is captured as a `phantom_usage` ledger entry rather than being clamped to 0 (BR-89). This preserves the true consumption signal for shrinkage audit. |
| 3.2 | System | Sends MSG07 critical low-stock alert to the Store Manager immediately. |

> **Note:** The system does **not** block order preparation due to insufficient stock. Operational continuity takes priority; the negative balance / phantom usage is flagged for manual audit by the Store Manager (it is **not** silently reset to zero — clamping would hide theft/over-pour and corrupt the count).

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-32 | *(Applies)* Any discrepancy between expected and actual counts must be noted. |
| BR-07 | **Inventory Deduction Timing**: Recipe-based stock for an order is deducted exactly once, when the order transitions from `PENDING` to `PREPARING` (UC-62, Barista taps "START PREP"). Every saleable item in the catalog is a prepared beverage/item that passes through the Barista queue, so this single trigger covers all stock movement — the chain sells no packaged/ready-to-serve goods that bypass preparation. Because cancellation is only permitted while the order is still `PENDING` (BR-05), no deduction has occurred at cancellation time, so no replenishment is ever required. |
| BR-89 | **Negative-Stock / Phantom-Usage Ledger**: When a deduction would exceed the available balance, the system records the full deduction and lets the `STOCK_ITEM` balance go **negative**, logging the shortfall as a `phantom_usage` stock-transaction entry (never clamping to 0). Negative balances surface in the low-stock alert (MSG07) and the COGS/shrinkage report (UC-76) so the loss signal is auditable and not silently erased. (RV-O16) |


