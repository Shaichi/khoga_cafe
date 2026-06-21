# 3.7 Order Management

This section details specifications for tracking orders, barista queue controls, stickers printing, and cancellation flows.

### Order Status State Machine

All orders follow the state transitions below:

```
[PENDING] --(Barista: START PREP)---> [PREPARING]
             \--(Cashier cancel)------> [CANCELLED]

[PREPARING] --(Barista: READY)--------> [READY]
             \--(Barista: REPORT ISSUE)-> [HOLD]

[HOLD] ----(Barista: RESUME PREP)--> [PREPARING]

[READY] -----(Cashier: handover/pickup)-> [COMPLETED]
        \----(auto-expiry / SM force-close)-> [ABANDONED]

[COMPLETED] → Terminal state (no further transitions)
[CANCELLED]  → Terminal state (no further transitions)
[ABANDONED]  → Terminal state (uncollected READY order; stock already deducted at PREPARING)
```

> **Note on COMPLETED state:** For DINE_IN and TAKE_AWAY orders, the transition from READY to COMPLETED is triggered by the Cashier confirming the order handover (customer pickup). For DELIVERY orders, it is triggered by delivery partner API sales report reconciliation.

> **Note on ABANDONED state (RV-O03):** A `READY` order that is never collected would otherwise block end-of-day shift close (BR-03 forbids closing while non-terminal orders exist). After `READY_ABANDON_TIMEOUT` (configurable) the system marks it `ABANDONED`, and the Store Manager may force-close remaining `READY` orders to `ABANDONED` at shift close (BR-88). Stock was already deducted at `PREPARING` (UC-62/BR-07), so no stock reversal occurs; the order is excluded from sales as uncollected.

> **HOLD state:** Triggered by the Barista via the "Report Issue" action when a preparation problem occurs (missing ingredient, equipment fault, etc.). A HOLD order remains visible in the Barista queue with a highlighted warning indicator. The Store Manager must be notified. The Barista can resume preparation (→ PREPARING) once the issue is resolved.

---

## 3.7.1 F35 - View Order List / UC-54 View Local Order History

### 3.7.1.1 Screen Mock-up (Mobile Portrait)
```
+------------------------------------+
|             Order List             |
|                                    |
|  Search: [ #012                  ] |
|  Status: [ All Statuses      ][v]  |
|                                    |
|  - Order #012 (Dine-in)       30k  |
|    Status: Preparing  (09:15)      |
|                                    |
|  - Order #011 (Take-away)    120k  |
|    Status: Ready      (09:05)      |
|                                    |
|                        [ Back ]    |
+------------------------------------+
```

#### Table 3-37: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Search | Text | No | 50 | Search by Order ID, sequence number, or customer name. |
| 2 | Status | Dropdown | Yes | | Filters list by order status. |
| 3 | Back | Button | | | Returns to dashboard portal. |

### 3.7.1.2 Use Case Description

| Use Case ID | UC-54 | Use Case Name | View Local Order History |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | Cashier, Store Manager, Barista |
| **Description** | Displays local branch orders processed during the current shift. |
| **Precondition** | User is logged in. |
| **Trigger** | User navigates to Order History. |
| **Post-Condition** | Displays local order list grid. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | User | Opens Order History screen. |
| 2 | Portal | Displays current branch orders list. |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-88 | **READY Order Auto-Abandon & Shift Close**: A `READY` order uncollected for longer than the configurable `READY_ABANDON_TIMEOUT` is auto-transitioned to the terminal state `ABANDONED`. At shift close, BR-03 still forbids closing while non-terminal orders exist, but the Store Manager may **force-close** any remaining `READY` orders to `ABANDONED` (logged with the approving manager). Because stock was deducted at `PREPARING` (UC-62/BR-07), no stock reversal occurs; `ABANDONED` orders are reported separately as uncollected and excluded from net sales. |

---

## 3.7.2 F36 - View Order Detail / UC-73 View Order Detail

### 3.7.2.1 Screen Mock-up (Mobile Portrait)
```
+------------------------------------+
|            Order Detail            |
|                                    |
|  Order Number: #012                |
|  ID: ORD-7890                      |
|  Type: Dine-in   Time: 09:15       |
|  Status: Preparing                 |
|                                    |
|  Items:                            |
|  - 1x Espresso (No sugar)      30k |
|                                    |
|  Total Paid: 30,000 VND (VietQR)   |
|                                    |
|       [ CANCEL ]    [ REPRINT ]    |
|                 [ BACK ]           |
+------------------------------------+
```

#### Table 3-38: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Cancel | Button | | | Opens Cancel Order view screen. |
| 2 | Reprint | Button | | | Resends ticket template data to receipt printer. |
| 3 | Back | Button | | | Returns to Order List screen. |

### 3.7.2.2 Use Case Description

| Use Case ID | UC-73 | Use Case Name | View Order Detail |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | Cashier, Store Manager, Barista |
| **Description** | Displays receipt details, payments, and fulfillment tracking metrics for an order. |
| **Precondition** | Order exists. |
| **Trigger** | User taps an order row. |
| **Post-Condition** | Displays detail card. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | User | Taps on specific order. |
| 2 | Portal | Displays details, payments log, and order item list. |

---

## 3.7.3 F37 - View Order Queue Display / UC-57 View Order Queue

### 3.7.3.1 Screen Mock-up (Mobile Landscape / Tablet)
```
+------------------------------------+
|           Barista Queue            |
|                                    |
|  - [ Preparing ] Order #012 (09:15)|
|    1x Espresso (No sugar)          |
|    [ READY ]      [ REPORT ISSUE ] |
|                                    |
|  - [ Pending ] Order #013   (09:20)|
|    1x Latte (Oat Milk)             |
|    [ START PREP ]                  |
+------------------------------------+
```

#### Table 3-39: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | START PREP | Button | | | Transitions order status from Pending to Preparing. |
| 2 | READY | Button | | | One-touch action. Transitions order status from Preparing to Ready and prints stickers without requiring any PIN or employee authentication. |
| 3 | REPORT ISSUE | Button | | | Puts order on Hold due to prep issue. |

### 3.7.3.2 Use Case Description

| Use Case ID | UC-57 | Use Case Name | View Order Queue Display |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | Barista |
| **Description** | Displays queue of active preparation orders sorted by oldest first. |
| **Precondition** | Barista is logged in. |
| **Trigger** | Barista accesses the queue dashboard. |
| **Post-Condition** | Queue is displayed. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | Barista | Opens the queue display. |
| 2 | Portal | Displays pending, preparing, and ready orders. |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-61 | **KDS KPI Aggregation Scope**: Barista performance indicators (e.g., average preparation time, orders completed per shift) are calculated and reported at the branch and shift session level. No performance metric is recorded per individual barista user ID for each beverage item. Reports expose aggregate throughput only. |
| BR-87 | [RESERVED / DELETED] |

---

## 3.7.4 F38 - Print Drink Label Sticker / UC-59 Print Drink Label Sticker

### 3.7.4.1 Screen Mock-up (Mobile Portrait Popup)
```
+------------------------------------+
|            Print Label             |
|                                    |
|       Print Sticker for drink:     |
|       Espresso - Order #012        |
|                                    |
|         [ PRINT ]   [ CLOSE ]      |
+------------------------------------+
```

#### Table 3-40: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Print | Button | | | Dispatches print job to sticker printer. |
| 2 | Close | Button | | | Closes modal window. |

### 3.7.4.2 Use Case Description

| Use Case ID | UC-59 | Use Case Name | Print Drink Label Sticker |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | Barista |
| **Description** | Prints cup stickers to identify beverage customization details. |
| **Precondition** | Order details are loaded. |
| **Trigger** | Barista clicks Print Sticker for drink item. |
| **Post-Condition** | Label is printed. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | Barista | Taps Print Sticker. |
| 2 | Portal | Dispatches item properties (Order number, modifications, time) to printer. |

---

## 3.7.5 F39 - Cancel Order / UC-55 Request Transaction Refund & Cancellation

### 3.7.5.1 Screen Mock-up (Mobile Portrait)
```
+------------------------------------+
|            Cancel Order            |
|                                    |
|  Reason for Cancellation *         |
|  [ Out of Milk ingredient      ][v]|
|                                    |
|  Notes *                           |
|  [ Discarded order, customer refund] |
|                                    |
|                                    |
|   [ HỦY BỎ ]     [ XÁC NHẬN HỦY ]  |
+------------------------------------+
```

#### Table 3-41: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Reason | Dropdown | Yes | | Cancellation reason mapping. |
| 2 | Notes | Text | Yes | 250 | Audit explanation. |
| 3 | Confirm | Button | | | Confirms cancellation, processes refund immediately, and returns to history. |
| 4 | Cancel | Button | | | Cancels the action and returns to the previous screen. |

### 3.7.5.2 Use Case Description

| Use Case ID | UC-55 | Use Case Name | Request Transaction Refund |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.3 |
| **Date** | 2026-06-02 | | |

| Field | Description |
|---|---|
| **Actor** | Cashier |
| **Description** | Voids a pending order and processes payment refund. |
| **Precondition** | Order is in `PENDING` state. |
| **Trigger** | Cashier clicks Cancel Order. |
| **Post-Condition** | Order is cancelled, stock rollbacked, and refund completed. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | Cashier | Selects a PENDING order, taps Cancel, inputs reason and detailed notes. |
| 2 | Cashier | Taps **Xác nhận hủy**. |
| 3 | Portal | Updates order status to `CANCELLED`, reverses vouchers/points (BR-08), records inventory wastage logs (BR-07), and saves cancellation audit logs. |
| 4 | Portal | Displays success notification and returns to order history screen. |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-05 | **Order Cancellation Rules**: Cancellation (voiding an order before preparation) is strictly restricted to the `PENDING` status; once the order transitions to `PREPARING`, the cancellation action is disabled for all users. Post-preparation complaints (wrong/spilled/slow) are **not** handled by cancellation — they use the Store-Manager-authorised Refund/Comp path (UC-75 / BR-67). |
| BR-06 | [RESERVED / DELETED] |
| BR-07 | **Inventory Deduction Timing**: Recipe-based stock for an order is deducted exactly once, when the order transitions from `PENDING` to `PREPARING` (UC-62, Barista taps "START PREP"). Every saleable item in the catalog is a prepared beverage/item that passes through the Barista queue, so this single trigger covers all stock movement — the chain sells no packaged/ready-to-serve goods that bypass preparation. Because cancellation is only permitted while the order is still `PENDING` (BR-05), no deduction has occurred at cancellation time, so no replenishment is ever required. |
| BR-08 | **Loyalty & Voucher Rollback**: Order cancellation reverses used vouchers (restoring total and customer limits) and adjusts loyalty points (gained points are deducted, and redeemed points are refunded to the customer balance). |

#### Data Requirements
To support cancellation auditing, the system must record:
- **Order Cancellation Logs**: Capturing the canceled order, the cashier who executed the cancellation, a mandatory cancellation reason, detailed notes, and the timestamp.

---

## 3.7.5a F39.1 - Refund / Comp After Preparation / UC-75 Store-Manager Refund or Comp

### 3.7.5a.1 Screen Mock-up (Mobile Portrait Modal)
```
+------------------------------------+
|        Refund / Comp Order         |
|        Order #A-1042  (READY)      |
|                                    |
|  Items:                            |
|   1x Peach Tea (L)      45,000 VND |
|   1x Espresso           30,000 VND |
|                                    |
|  Action:                           |
|   (x) Refund    ( ) Comp / Remake  |
|  Refund amount:                    |
|   (x) Full (75,000)  ( ) Item [v]  |
|                                    |
|  Reason: [ Wrong item         ][v] |
|  Notes:  [ Customer got latte    ] |
|                                    |
|  --- Store Manager authorisation --|
|  SM PIN: [ ____ ]    or [ SM Login ]|
|                                    |
|      [ Confirm ]      [ Cancel ]   |
+------------------------------------+
```

#### Table 3-63: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Action | Radio | Yes | | `Refund` (return money) or `Comp / Remake` (zero-charge replacement). |
| 2 | Refund amount | Radio + Selector | Conditional | | `Full` or a specific line item (partial refund). Required when Action = Refund. |
| 3 | Reason | Dropdown | Yes | | Complaint reason (Wrong item, Spilled, Too slow, Quality, Other). |
| 4 | Notes | Text | No | 255 | Free-text detail for the audit record. |
| 5 | SM PIN / SM Login | Auth | Yes | | Store Manager authorisation — 4-digit SM PIN or SM login. Recorded as `sm_id` (BR-67). |
| 6 | Confirm | Button | | | Processes the refund/comp and writes the `ORDER_REFUND` audit record. |
| 7 | Cancel | Button | | | Closes the modal with no change. |

### 3.7.5a.2 Use Case Description

| Use Case ID | UC-75 | Use Case Name | Store-Manager Refund or Comp |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-06-13 | | |

| Field | Description |
|---|---|
| **Actor** | Store Manager (authoriser); Cashier may initiate the request |
| **Description** | Handles customer complaints that arise **after** preparation has started — when the order is `PREPARING`, `READY`, or already `COMPLETED` and therefore cannot be cancelled (BR-05). The Store Manager authorises either a **Refund** (return money) or a **Comp / Remake** (replacement at no charge). The order's preparation/sales history is preserved; a refund record is attached. |
| **Precondition** | Order is in `PREPARING`, `READY`, or `COMPLETED`; payment was captured. A Store Manager is available to authorise. |
| **Trigger** | Cashier opens Order Detail of a post-`PENDING` order and taps **Refund / Comp**. |
| **Post-Condition** | A refund/comp record is logged with the approving `sm_id`; money and loyalty effects are applied per BR-67. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | Cashier | Opens the order in Order Detail and taps **Refund / Comp**. |
| 2 | Store Manager | Authorises via SM login or SM PIN. |
| 3 | Store Manager | Selects type — **Refund** (full or partial amount) or **Comp / Remake** — and enters reason + notes. |
| 4 | Portal | If **Refund**: returns money per BR-67 (cash → currently-open shift drawer per BR-09; card/VietQR → payment gateway) and reverses loyalty per BR-08. If **Comp / Remake**: pushes a new zero-charge line to the Barista queue (which deducts stock again at its `PREPARING` per UC-62). |
| 5 | Portal | Writes an `order_refunds` audit record (`order_id`, `sm_id`, `cashier_id`, type, amount, reason, notes) and surfaces it on the Store Manager dashboard. |

#### Business Rules
| BR-67 | **Store-Manager Refund / Comp (post-PENDING)**: Orders past `PENDING` cannot be cancelled (BR-05) but may be refunded or comped with **Store Manager authorisation** (SM login or SM PIN), always logged with the approving `sm_id`. Cash refunds debit the currently-open shift drawer (BR-09; card/VietQR refunds go through the payment gateway. A refund reverses accrued loyalty points and restores redeemed points proportionally to the refunded amount (per BR-08). **Partial / single-line-item refunds are permitted.** A Comp / Remake issues a zero-charge replacement that re-enters the prep queue and deducts stock again (UC-62). The original order's prep/sales history is preserved (not voided). |

#### Data Requirements
To support refund/comp auditing, the system must record:
- **Order Refund/Comp Logs**: For Store-Manager authorized refunds or comps past the PENDING state, capturing the order, the authorizing Store Manager, the initiating cashier, the active shift session (for cash refunds), the refund type (standard refund or comp remake), the refund amount, the reason, notes, and the timestamp.


