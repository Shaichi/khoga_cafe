# 3.8 Customer & Membership Management

This section details specifications for loyalty membership profiles search, enrollment, and history views.

---

### 3.8.1.1 Screen Mock-up (Mobile Portrait)
```
+------------------------------------+
|             Customers              |
|                                    |
|  Search: [ 0987654321            ] |
|                                    |
|  - Nguyen Van A                    |
|    Phone: 0987654321  (340 pts)    |
|                                    |
|  - Tran Thi B                      |
|    Phone: 0912345678  (120 pts)    |
|                                    |
|          [ + Add Customer ]        |
+------------------------------------+
```

#### Table 3-42: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Search | Text | No | 50 | Filter members by phone number or name. |
| 2 | Add Customer | Button | | | Navigates to Add Customer registration screen. |

### 3.8.1.2 Use Case Description

| Use Case ID | UC-24 | Use Case Name | View Customer List |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.1 |
| **Date** | 2026-06-03 | | |

| Field | Description |
|---|---|
| **Actor** | Cashier, Store Manager, Business Admin |
| **Description** | Displays the register of all enrolled loyalty members. |
| **Precondition** | User is logged in. |
| **Trigger** | User navigates to Customers module. |
| **Post-Condition** | Displays membership registry. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | User | Opens Customers directory. |
| 2 | Portal | Displays listing grid of enrolled members and their points balance. |

---

## 3.8.2 F41 - Add Customer / UC-25 Add Customer

### 3.8.2.1 Screen Mock-up (Mobile Portrait)
```
+------------------------------------+
|            Add Customer            |
|                                    |
|  Full Name                         |
|  [ Nguyen Van A                  ] |
|                                    |
|  Phone Number                      |
|  [ 0987654321                    ] |
|                                    |
|  Contact Email (Optional)          |
|  [ nva@example.com               ] |
|                                    |
|        [ REGISTER ]   [ CANCEL ]   |
+------------------------------------+
```

#### Table 3-43: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Full Name | Text | Yes | 100 | Customer's full name. |
| 2 | Phone Number | Text | Yes | 20 | Customer phone number lookup key. |
| 3 | Contact Email | Text | No | 100 | Customer email address. |
| 4 | Register | Button | | | Submits details to enroll customer. |
| 5 | Cancel | Button | | | Returns to Customers list. |

### 3.8.2.2 Use Case Description

| Use Case ID | UC-25 | Use Case Name | Add Customer |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

|---|---|
| **Actor** | Cashier, Store Manager, Business Admin |
| **Description** | Registers a new customer into the membership loyalty program. |
| **Precondition** | Customer is not enrolled. |
| **Trigger** | User clicks "+ Add Customer". |
| **Post-Condition** | Customer is registered as a loyalty member. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | User | Enters customer Name, Phone, and optional Email, and confirms the customer has **consented** to enrolment and to processing of their personal data for the loyalty program (BR-71). Clicks "Register". |
| 2 | Portal | Validates phone syntax format and checks for duplicates. |
| 3 | Portal | Saves new customer record with 0 starting points, stamping `consent_at` and `consent_version`, and returning to list view. |
#### Alternative Flows
##### AT1: Phone Number Duplicate
- **Trigger**: At step 2, phone number is already registered.

| Sub-step | Actor | Action |
|---|---|---|
| 2.1 | Portal | Displays warning message: `"A member with this phone number is already registered."` |

##### AT2: Invalid Phone Format
- **Trigger**: At step 2, phone number does not fit 10-11 digits pattern.

| Sub-step | Actor | Action |
|---|---|---|
| 2.1 | Portal | Displays warning message: `"Please enter a valid phone number (10-11 digits)."` |

##### AT3: Consent Not Given
- **Trigger**: At step 1, the consent confirmation is not checked.

| Sub-step | Actor | Action |
|---|---|---|
| 1.1 | Portal | Disables "Register" and displays: `"Customer consent is required to enrol a member and store their personal data."` |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-71 | **Customer PII Consent (PDPA / Decree 13/2023)**: Enrolling a customer requires recorded consent to process their personal data (phone, optional email, purchase history) for the loyalty program. The system stamps `consent_at` (timestamp) and `consent_version` on the `CUSTOMER` record at registration. A customer may later withdraw consent, which triggers the erasure/anonymisation flow in BR-72. |
| BR-72 | **Personal Data Retention & Erasure**: Customer PII is retained for **24 months from the last transaction**, after which the record is **anonymised** (phone/email/name irreversibly hashed or nulled; aggregate sales history retained without PII). Attendance camera snapshots (`photo_url`) are auto-deleted **90 days** after capture (`photo_purge_at`), with the attendance row preserved for payroll. The system supports an **on-request erasure/anonymisation** action for a specific customer (data-subject request) ahead of the 24-month window. Erasure must preserve legally mandated financial records (orders/payments per §4.2.6) by detaching PII rather than deleting the transaction. |

---

## 3.8.3 F42 - Update Customer / UC-26 Update Customer

### 3.8.3.1 Screen Mock-up (Mobile Portrait)
```
+------------------------------------+
|           Edit Customer            |
|                                    |
|  Full Name                         |
|  [ Nguyen Van A                  ] |
|                                    |
|  Phone: 0987654321  (Read-only)    |
|                                    |
|  Contact Email                     |
|  [ nva@example.com               ] |
|                                    |
|  Adjust Points (Business Admin):   |
|  Points: [ 340      ]              |
|  Reason: [ Dispute Resolution    ] |
|                                    |
|        [ SAVE ]   [ CANCEL ]       |
+------------------------------------+
```

#### Table 3-44: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Full Name | Text | Yes | 100 | Customer's full name (editable). |
| 2 | Phone | Label | | | Customer phone number lookup key (read-only/locked). |
| 3 | Contact Email | Text | Yes | 100 | Customer email address. |
| 4 | Points | Text | Conditional | 6 | **Visible and editable only when Actor = Business Admin.** Hidden/read-only for Cashier and Store Manager roles. |
| 5 | Reason | Text | Conditional | 250 | **Mandatory when Points value is changed (Business Admin only).** Explanation comment for manual points adjustment. |
| 6 | Save | Button | | | Saves customer details changes. |
| 7 | Cancel | Button | | | Returns to list page. |

### 3.8.3.2 Use Case Description

| Use Case ID | UC-26 | Use Case Name | Update Customer |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | Cashier, Store Manager, Business Admin |
| **Description** | Modifies membership contact details or adjusts points logs. |
| **Precondition** | Customer profile exists. |
| **Trigger** | User clicks edit row icon on list view. |
| **Post-Condition** | Customer metadata is updated. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | User | Modifies Full Name or Contact Email (or Business Admin inputs point changes) and clicks "Save". |
| 2 | Portal | Validates inputs. |
| 3 | Portal | Updates details, logs adjust audit notes (if point changes occur), and returns. |

#### Alternative Flows
##### AT1: Non-Business-Admin Actor — Points Fields Hidden
- **Trigger**: Cashier or Store Manager opens the Edit Customer screen.

| Sub-step | Actor | Action |
|---|---|---|
| 1 | Portal | The "Points" and "Reason" fields are hidden from the form. Only "Contact Email" is editable. |

##### AT2: Points Changed Without Reason
- **Trigger**: Business Admin modifies the Points value but leaves Reason blank.

| Sub-step | Actor | Action |
|---|---|---|
| 2.1 | Portal | Displays error message: `"A reason is required when manually adjusting customer points."` |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-49 | Manual points adjustments require a recorded reason and are locked to Business Admin role. |

## 3.8.4 F43 - View Customer History / UC-27 View Customer History

### 3.8.4.1 Screen Mock-up (Mobile Portrait)
```
+------------------------------------+
|          Customer History          |
|                                    |
|  Customer: Nguyen Van A            |
|  Phone: 0987654321  Points: 340    |
|                                    |
|  Completed Orders:                 |
|  - 2026-05-24: #012  (Total: 30k)  |
|    +3 points accumulated.          |
|                                    |
|  - 2026-05-20: #005  (Total: 70k)  |
|    +7 points accumulated.          |
|                                    |
|                        [ Back ]    |
+------------------------------------+
```

#### Table 3-45: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Back | Button | | | Returns to Customer card. |

### 3.8.4.2 Use Case Description

| Use Case ID | UC-27 | Use Case Name | View Customer History |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.1 |
| **Date** | 2026-06-03 | | |

| Field | Description |
|---|---|
| **Actor** | Cashier, Store Manager, Business Admin |
| **Description** | Lists all historical orders completed by the customer. |
| **Precondition** | Customer is selected. |
| **Trigger** | User navigates to Transaction History view in profile card. |
| **Post-Condition** | Customer order logs are displayed. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | User | Opens customer transaction history screen. |
| 2 | Portal | Retrieves and displays order details, item names, and points earned. |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-34 | **[RESERVED / DELETED]** (Previously: Real-Time Membership Tier Levels). |
| BR-35 | **Loyalty Points Expiry**: Loyalty points expire after 12 months of customer inactivity (no new transactions made by the customer). |
