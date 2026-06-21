# 3.9 Staff Management

This section details specifications for staff shifts assignment, schedules views, and schedules cancellations.

---

## 3.9.1 F44 - Create Staff Schedule / UC-36 Create Staff Schedule

### 3.9.1.1 Screen Mock-up (Mobile Portrait)
```
+------------------------------------+
|          Create Schedule           |
|                                    |
|  Employee                          |
|  [ Nguyen Van A                ][v]|
|                                    |
|  Date                              |
|  [ 2026-05-25                    ] |
|                                    |
|  Shift Type                        |
|  [ Morning (06:00 - 14:00)     ][v]|
|                                    |
|  Allocated POS Register            |
|  [ REG-01                      ][v]|
|                                    |
|         [ ASSIGN ]   [ CANCEL ]    |
+------------------------------------+
```

#### Table 3-46: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Employee | Dropdown | Yes | | Active employee user accounts list. |
| 2 | Date | Date | Yes | | Target scheduling date calendar. |
| 3 | Shift Type | Dropdown | Yes | | Shift duration (`Morning`, `Afternoon`, `Full-Day`). |
| 4 | Allocated POS Register | Dropdown | Conditional | | POS terminal register allocation. **Mandatory when Employee role = `CASHIER`; Optional (leave blank) when role = `BARISTA` or `STORE_MANAGER`.** |
| 5 | Assign | Button | | | Submits details to schedule shift. |
| 6 | Cancel | Button | | | Returns to Shift Schedule view. |

### 3.9.1.2 Use Case Description

| Use Case ID | UC-36 | Use Case Name | Create Staff Schedule |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | Store Manager |
| **Description** | Assigns employee to an operational work shift. |
| **Precondition** | Manager is logged in. |
| **Trigger** | Manager taps "Assign Shift" button on calendar scheduler. |
| **Post-Condition** | Shift schedule is updated. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | Manager | Selects Employee, Date, **Start/End time** (or Shift Type), POS Register, and **target Branch** (defaults to the manager's own branch; may be another branch for cross-branch help — BR-90), then clicks "Assign". |
| 2 | Portal | Validates schedule availability (conflict check) **and** labour constraints — max daily/weekly hours, minimum rest between shifts, and the branch labour-hour budget (BR-92). |
| 3 | Portal | Saves the shift session and updates the schedule calendar. If the target branch differs from the employee's home branch, writes a cross-branch assignment audit entry (BR-90). |

#### Alternative Flows
##### AT1: Schedule Conflict
- **Trigger**: At step 2, target employee is already assigned to a shift on that date.

| Sub-step | Actor | Action |
|---|---|---|
| 2.1 | Portal | Displays conflict error message: "Employee shift conflict. The employee is already scheduled..." (MSG12). |

##### AT2: Labour Constraint Exceeded
- **Trigger**: At step 2, the assignment would breach max daily/weekly hours, the minimum-rest gap, or the branch labour-hour budget.

| Sub-step | Actor | Action |
|---|---|---|
| 2.1 | Portal | Warns the Manager: `"This shift exceeds {max hours / rest gap / labour budget}. Adjust or confirm override."` Hard limits (max hours, rest) block; the labour-budget cap is a soft warning the Manager may override with a reason (logged). (BR-92) |

##### AT3: Cross-Branch Assignment
- **Trigger**: At step 1, the Manager selects a target branch other than the employee's home branch.

| Sub-step | Actor | Action |
|---|---|---|
| 3.1 | Portal | Creates the shift at the target branch, audit-logs the cross-branch assignment (`employee_id`, home `store_id`, target `store_id`, actor SM, date), and makes the borrowed employee visible to the **host** branch's Store Manager for that shift (BR-90 / BR-59 exception). No host approval is required. |

---

## 3.9.2 F45 - View Staff Schedule / UC-35 View Staff Schedule

### 3.9.2.1 Screen Mock-up (Mobile Portrait)
```
+------------------------------------+
|           Shift Schedule           |
|                                    |
|  Filter: [ All Roles           ][v]  |
|  Date: [ 2026-05-25            ]   |
|                                    |
|  - Nguyen Van A (Cashier)          |
|    Morning (06:00 - 14:00) - REG-01|
|                                    |
|  - Tran Thi B (Barista)            |
|    Morning (06:00 - 14:00)         |
|                                    |
|        [ + Add ]   [ Back ]        |
+------------------------------------+
```

#### Table 3-47: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Filter | Dropdown | Yes | | Filters list by employee roles. |
| 2 | Date | Date | Yes | | Jumps display date. |
| 3 | Add | Button | | | Navigates to Create Staff Schedule view. |
| 4 | Back | Button | | | Returns to dashboard. |

### 3.9.2.2 Use Case Description

| Use Case ID | UC-35 | Use Case Name | View Staff Schedule |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | Store Manager, Cashier, Barista |
| **Description** | Displays shift assignments in calendar format. |
| **Precondition** | User is logged in. |
| **Trigger** | User opens shift schedule calendar menu. |
| **Post-Condition** | Displays shift schedule list. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | User | Opens schedule dashboard view. |
| 2 | Portal | Retrieves active schedules for selected role/date filters and displays them. |

---

## 3.9.3 F46 - Update/Delete Staff Schedule / UC-37, UC-38 Edit/Remove Shift

### 3.9.3.1 Screen Mock-up (Mobile Portrait)
```
+------------------------------------+
|           Modify Shift             |
|                                    |
|  Employee: Nguyen Van A            |
|  Date: 2026-05-25                  |
|                                    |
|  Shift Type                        |
|  [ Afternoon (14:00-22:00)     ][v]|
|                                    |
|  Register                          |
|  [ REG-01                      ][v]|
|                                    |
|        [ SAVE ]   [ DELETE ]       |
|               [ CANCEL ]           |
+------------------------------------+
```

#### Table 3-48: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Shift Type | Dropdown | Yes | | Select shift hours. |
| 2 | Register | Dropdown | Yes | | Select target register. |
| 3 | Save | Button | | | Submits modifications to scheduled shift. |
| 4 | Delete | Button | | | Deletes shift scheduling. |
| 5 | Cancel | Button | | | Discards changes. |

### 3.9.3.2 Use Case Description

| Use Case ID | UC-37 | Use Case Name | Update Staff Schedule |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | Store Manager |
| **Description** | Modifies or deletes shift assignments. |
| **Precondition** | Shift schedule is scheduled in the future. |
| **Trigger** | Manager taps on a scheduled shift row on the calendar. |
| **Post-Condition** | Shift schedule details are updated. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | Manager | Selects scheduled shift cell, modifies values, and taps "Save" (or clicks "Delete"). |
| 2 | Portal | Validates inputs. |
| 3 | Portal | Updates shift schedule calendar view and syncs notifications. |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-36 | Cannot modify schedules that occurred in the past. |
| BR-37 | Deletion removes the shift and sends notification alerts to affected employees. |

---

## 3.9.4 F46.1 - View Staff Attendance Report / UC-39 View Staff Attendance Report

### 3.9.4.1 Screen Mock-up (Mobile Portrait)
```
+------------------------------------+
|         Attendance Report          |
|                                    |
|  Date: [ 2026-05-24 ]              |
|  Filter: [ Late Only           ][v]  |
|                                    |
|  - Nguyen Van A (Cashier)          |
|    Check-in: 06:15 AM (Late 15m)   |
|    Check-out: 14:02 PM             |
|                                    |
|  - Tran Thi B (Barista)            |
|    Check-in: 05:58 AM (On Time)    |
|    Check-out: 14:00 PM             |
|                                    |
|                        [ Back ]    |
+------------------------------------+
```

#### Table 3-49: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Date | Date | Yes | | Target scheduling date calendar. |
| 2 | Filter | Dropdown | Yes | | Filters list by attendance categories (`All`, `Late Only`, `Absent`). |
| 3 | Back | Button | | | Returns to Shift Schedule view. |

### 3.9.4.2 Use Case Description

| Use Case ID | UC-39 | Use Case Name | View Staff Attendance Report |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | Store Manager |
| **Description** | Accesses and reviews daily check-in and check-out logs for store staff. |
| **Precondition** | Store Manager is logged in. |
| **Trigger** | Store Manager clicks "View Attendance Report" button from the Shift Schedule screen. |
| **Post-Condition** | Attendance logs for the selected date are displayed. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | Store Manager | Selects a date and filter option. |
| 2 | Portal | Retrieves attendance records for the selected filters. |
| 3 | Portal | Displays employee name, actual check-in/out times, and calculated lateness. |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-38 | **Attendance Log Recording**: The system records check-in and check-out entries under the local branch where the attendance action was taken. At check-in, the system snapshots the scheduled shift's start time (which may be empty for cross-branch walk-in employees with no schedule) so lateness can be calculated historically even if the schedule is later edited. |
| BR-39 | **Lateness Calculation**: Lateness is calculated dynamically as the duration between the actual check-in time and the scheduled shift start time. Both times must be converted to the local branch's timezone before calculation. Check-ins at or before the scheduled start time incur zero lateness. Lateness is not calculated for walk-in shifts that have no scheduled start time. |
| BR-53 | **Attendance Check-in & Check-out**: Staff check-in and check-out are performed via a dedicated attendance popup by entering a personal 4-digit PIN and taking a camera snapshot. This action is independent of the active terminal session login — the shared POS session on the terminal is not interrupted. |
| BR-90 | **Cross-Branch Shift Assignment**: A Store Manager may assign one of their own-branch employees to a shift at another branch directly (no host approval) via UC-36. The assignment is audit-logged (capturing the employee, home and target branches, assigning manager, and date) and makes the borrowed employee visible to the host Store Manager for that shift's duration (BR-59 exception). Worked hours follow the employee for payroll, and branch labor costs are attributed to the branch where the shift was physically worked (BR-53a). (RV-C04) |
| BR-91 | **Absence & OT / Early-Leave Derivation**: From scheduled shifts vs attendance entries, the system derives, per employee per day: **Absence** = a scheduled shift with no check-in; **Overtime** = worked hours beyond the scheduled shift length; **Early-Leave** = check-out before the scheduled end. These are non-monetary metrics surfaced on the attendance and worked-hours reports — payroll processing remains external (§1.2) and no in-system leave-request workflow is provided. (RV-C06) |
| BR-92 | **Labour Budget & Working-Time Validation**: At scheduling, the system enforces configurable working-time limits — maximum daily/weekly working hours and minimum rest hours between consecutive shifts (hard blocks) — and a per-branch labor hour budget per period (soft warning the Store Manager may override with a logged reason). |
| BR-93 | **Attendance PIN Uniqueness & Mandatory Photo**: An attendance PIN must be unique within its branch and is locked after a configurable number of failed entries. The camera snapshot is mandatory at check-in/out; if the camera is unavailable, the action is queued and flagged for Store Manager confirmation rather than recorded without a photo — closing the buddy-punching gap. (RV-C08) |

### 3.9.4.3 Attendance Logs Data Requirements

To support attendance logging, fraud prevention, and compliance, the system must record:
- **Attendance Records**: Capturing the employee, the physical branch where the action was taken, the optional scheduled shift, a snapshot of the shift's scheduled start time (captured at check-in), the action type (check-in or check-out), and the timestamp. Storing the scheduled start time at check-in ensures historical lateness calculations are immune to subsequent roster edits.
- **Biometric Photo Auditing & Erasure**: Storing the camera snapshot URL taken during the attendance action (required for clock-in fraud prevention), and a scheduled erasure date for the snapshot (set to capture date + 90 days). The photo URL must be deleted automatically after 90 days (per BR-72) while preserving the attendance log row (times and lateness data) for payroll history.

---

## 3.9.5 F46.2 - View Branch Staff List / UC-66 View Branch Staff List

### 3.9.5.1 Screen Mock-up (Mobile Portrait)
```
+------------------------------------+
|            Branch Staff            |
|                      [Nguyen Du]   |
|                                    |
|  [ 8 ]      [ 3 ]      [ 4 ]       |
|  Total      Cashier    Barista     |
|                                    |
|  Filter: [ All ][ Cashier ][ Barista ]
|                                    |
|  - Nguyen Van An (Cashier)     [C] |
|    Phone: 0901 234 567             |
|    Status: Active                  |
|                                    |
|  - Tran Thi Binh (Cashier)     [C] |
|    Phone: 0912 345 678             |
|    Status: Active                  |
|                                    |
|                           [ Back ] |
+------------------------------------+
```

#### Table 3-50: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Stats Grid | Display | - | | Shows counts of Total Staff, Cashiers, Baristas, Managers. |
| 2 | Filter Tabs | Button Row | Yes | | Filters list by roles (`All`, `Cashier`, `Barista`, `Manager`). |
| 3 | Call Action (C) | Button | No | | Triggers mobile native phone call to the staff member. |
| 4 | Staff Card Click | Interactive | - | | Opens detailed information modal overlay. |
| 5 | Back | Button | - | | Returns to Manager Dashboard console. |

### 3.9.5.2 Use Case Description

| Use Case ID | UC-66 | Use Case Name | View Branch Staff List |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-06-02 | | |

| Field | Description |
|---|---|
| **Actor** | Store Manager |
| **Description** | Reviews the roster list and contact profiles of staff assigned to their branch. |
| **Precondition** | Manager is logged in and viewing their local branch dashboard. |
| **Trigger** | Manager taps the "Nhân Viên" menu button on the Dashboard. |
| **Post-Condition** | Displays active/inactive local branch employee profiles. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | Store Manager | Opens the Branch Staff list module. |
| 2 | Portal | Retrieves active and deactivated users whose assigned branch matches the manager's branch. |
| 3 | Portal | Shows aggregated stats and lists cards containing Names, Roles, Contacts and Badges. |
| 4 | Store Manager | (Optional) Taps on a Staff Card to open detail modal or triggers instant call link. |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-59 | **Branch Staff Isolation & Read-Only**: A Store Manager can only view, search, and call their local staff. All mutation capabilities (create, modify role, deactivate user, update PIN) are restricted to the System Admin (`ssadmin`). A Store Manager must not view rosters or contact details of staff registered at other branches — **except** an employee currently assigned a cross-branch shift at the manager's branch, who becomes visible to that host Store Manager for the duration of the assignment (BR-90). |

---

## 3.9.6 F46.3 - Export Worked-Hours Report / UC-80 Export Worked-Hours Report

### 3.9.6.1 Screen Mock-up (Mobile / Tablet Portrait)
```
+------------------------------------+
|       Worked-Hours Export          |
|                                    |
|  Branch: District 1 (yours)        |
|  Period: [2026-05-01]–[2026-05-31] |
|                                    |
|  Employee        Days  Hours  Flag |
|  Nguyen Van An    24   188.5    -  |
|  Tran Thi Binh    22   171.0   (1) |
|  Le Van Cuong     20   152.5    -  |
|  ........................          |
|  (1) = 1 day with missing checkout |
|                                    |
|  [ Export CSV ]   [ Export PDF ]   |
+------------------------------------+
```

#### Table 3-69: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Period | Date Picker | Yes | | Pay-period window (branch-local, §5.2.2). |
| 2 | Employee rows | Grid | | | Per employee: days worked, total worked-hours (BR-77), and a flag count of days with missing/unpaired checkout. |
| 3 | Missing-checkout flag | Indicator | | | Days with a `CHECK_IN` but no matching `CHECK_OUT` are flagged for manual correction and **excluded** from the hours total (BR-77). |
| 4 | Export CSV / PDF | Button | | | Generates the worked-hours file to feed the external payroll/accounting system (§1.2). |

### 3.9.6.2 Use Case Description

| Use Case ID | UC-80 | Use Case Name | Export Worked-Hours Report |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-06-14 | | |

| Field | Description |
|---|---|
| **Actor** | Store Manager (own branch only) |
| **Description** | Produces a per-employee **worked-hours** summary for a pay period at the manager's branch, exportable as CSV/PDF to feed the **external** payroll system. The system computes hours only — it does **not** calculate or pay wages (§1.2). Cross-branch shifts are attributed per BR-53a (payroll hours follow `employee_id`). |
| **Precondition** | Store Manager is logged in and viewing their own branch. |
| **Trigger** | Store Manager opens "Worked-Hours Export" and selects a period. |
| **Post-Condition** | A worked-hours file is generated; days needing correction are flagged. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | Store Manager | Selects the pay period. |
| 2 | Portal | Pairs each `CHECK_IN` with its next `CHECK_OUT` per employee per day and sums the durations (BR-77). |
| 3 | Portal | Lists per-employee days and total hours, flagging any day with a missing checkout. |
| 4 | Store Manager | Clicks Export CSV / PDF to download the file for external payroll. |

#### Alternative Flows
##### AT1: Missing Checkout
- **Trigger**: At step 2, an employee has a `CHECK_IN` with no matching `CHECK_OUT` for that day.

| Sub-step | Actor | Action |
|---|---|---|
| 2.1 | Portal | Flags that day, excludes it from the hours total, and surfaces it for manual correction before export. |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-77 | **Worked-Hours Computation**: For each employee, worked hours are calculated per business day as the sum of all paired check-in and check-out durations. Any incomplete attendance entry (missing check-in or check-out) is flagged for manager review and excluded from calculations. The system aggregates worked hours per employee to support payroll processing (BR-53a), but does not perform currency-based wage calculations (§1.2). The reports feed an external payroll system. |


