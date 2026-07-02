## **2\. Database Design**

*\[The database design follows the entity relationships defined in the SRS (§3.1.5 / §3.1.6). The system uses `SQL Server` with ACID transactions and Unicode support (`NVARCHAR`). All primary keys use `UUID` (`VARCHAR(36)`). The diagrams below show the entity relationships with full column definitions, followed by the table descriptions. Every table also carries an `updated_at` column from the shared `BaseEntity` (JPA auditing), omitted from the diagrams for brevity. The live schema is entity-driven (`ddl-auto=update`) — there are **23 tables**; generated names are concatenated-lowercase (e.g. `categorys`, `menuitems`) pending naming normalization under Flyway (P4).\]*

### **2.1. Core Sales & POS ERD**

*\[This diagram focuses on sales flows at the POS terminal, Menu information, Customers, Shift sessions, and Promotions.\]*

```mermaid
erDiagram
    STORE {
        UNIQUEIDENTIFIER id PK
        NVARCHAR(255) name
        NVARCHAR(255) address
        NVARCHAR(255) phone
        BIT is_active
        DATETIME2 created_at
    }

    USER {
        UNIQUEIDENTIFIER id PK
        NVARCHAR(255) username
        NVARCHAR(255) password_hash
        VARCHAR(50) role
        NVARCHAR(255) full_name
        BIT is_active
        NVARCHAR(255) email
        NVARCHAR(255) phone
        UNIQUEIDENTIFIER store_id FK
        NVARCHAR(255) employee_id
        INT failed_attempts
        DATETIME2 lock_expiry_at
        DATETIME2 password_last_changed_at
        DATETIME2 created_at
        DATETIME2 last_login_at
        BIT must_change_password
        NVARCHAR(255) attendance_pin
    }

    CATEGORY {
        UNIQUEIDENTIFIER id PK
        NVARCHAR(255) name
        NVARCHAR(MAX) description
        BIT is_active
    }

    MENU_ITEM {
        UNIQUEIDENTIFIER id PK
        UNIQUEIDENTIFIER category_id FK
        UNIQUEIDENTIFIER parent_item_id FK
        NVARCHAR(255) name
        DECIMAL(18,2) price
        NVARCHAR(MAX) description
        BIT is_active
        NVARCHAR(255) image_url
        NVARCHAR(255) barcode
        NVARCHAR(255) sku
        NVARCHAR(255) size_name
        NVARCHAR(255) abbreviation
        DATETIME2 created_at
        BIT is_deleted
    }

    BRANCH_MENU_STATUS {
        UNIQUEIDENTIFIER store_id PK
        UNIQUEIDENTIFIER menu_item_id PK
        BIT is_available
    }

    OPTION_TOPPING {
        UNIQUEIDENTIFIER id PK
        NVARCHAR(255) name
        DECIMAL(18,2) price
        BIT is_active
    }

    CUSTOMER {
        UNIQUEIDENTIFIER id PK
        NVARCHAR(255) phone
        NVARCHAR(255) full_name
        INT points
        NVARCHAR(255) email
        DATE birth_date
        BIT is_active
        DATETIME2 created_at
        DATETIME2 consent_at
        NVARCHAR(255) consent_version
    }

    MENU_ITEM_TOPPING_MAPPING {
        UNIQUEIDENTIFIER id PK
        UNIQUEIDENTIFIER menu_item_id FK
        UNIQUEIDENTIFIER option_topping_id FK
    }

    SHIFT_SESSION {
        UNIQUEIDENTIFIER id PK
        UNIQUEIDENTIFIER store_id FK
        UNIQUEIDENTIFIER user_id FK
        DATETIME2 start_time
        DATETIME2 end_time
        DECIMAL(18,2) starting_cash
        DECIMAL(18,2) ending_cash
        VARCHAR(50) status
        NVARCHAR(255) pos_register_id
    }

    ORDER {
        UNIQUEIDENTIFIER id PK
        UNIQUEIDENTIFIER store_id FK
        NVARCHAR(255) order_number
        UNIQUEIDENTIFIER shift_session_id FK
        UNIQUEIDENTIFIER customer_id FK
        UNIQUEIDENTIFIER voucher_id FK
        VARCHAR(50) order_type
        DECIMAL(18,2) subtotal
        DECIMAL(18,2) discount
        DECIMAL(18,2) tax_amount
        DECIMAL(18,2) total
        VARCHAR(50) payment_method
        VARCHAR(50) payment_status
        VARCHAR(50) status
        DATETIME2 created_at
    }

    ORDER_ITEM {
        UNIQUEIDENTIFIER id PK
        UNIQUEIDENTIFIER order_id FK
        UNIQUEIDENTIFIER menu_item_id FK
        INT quantity
        DECIMAL(18,2) unit_price
    }

    ORDER_ITEM_TOPPING {
        UNIQUEIDENTIFIER id PK
        UNIQUEIDENTIFIER order_item_id FK
        UNIQUEIDENTIFIER topping_id FK
        INT quantity
        DECIMAL(18,2) unit_price
    }

    ORDER_CANCELLATION {
        UNIQUEIDENTIFIER id PK
        UNIQUEIDENTIFIER order_id FK
        UNIQUEIDENTIFIER cashier_id FK
        NVARCHAR(255) reason
        NVARCHAR(MAX) notes
        DATETIME2 created_at
    }

    ORDER_REFUND {
        UNIQUEIDENTIFIER id PK
        UNIQUEIDENTIFIER order_id FK
        UNIQUEIDENTIFIER sm_id FK
        UNIQUEIDENTIFIER cashier_id FK
        UNIQUEIDENTIFIER shift_session_id FK
        VARCHAR(50) refund_type
        DECIMAL(18,2) amount
        NVARCHAR(255) reason
        NVARCHAR(MAX) notes
        DATETIME2 created_at
    }

    VOUCHER {
        UNIQUEIDENTIFIER id PK
        NVARCHAR(255) code
        VARCHAR(50) discount_type
        DECIMAL(18,2) discount_value
        DECIMAL(18,2) min_order_value
        DATETIME2 start_date
        DATETIME2 end_date
        BIT is_active
        INT usage_limit_per_customer
        INT total_usage_count
        INT max_total_uses
        DECIMAL(18,2) max_discount_amount
    }

    %% Relationships
    STORE ||--o{ USER : "contains"
    STORE ||--o{ SHIFT_SESSION : "hosts"
    STORE ||--o{ ORDER : "receives"
    STORE ||--o{ BRANCH_MENU_STATUS : "manages"

    USER ||--o{ SHIFT_SESSION : "opens"
    USER ||--o{ ORDER_CANCELLATION : "executes"
    USER ||--o{ ORDER_REFUND : "authorises"

    CATEGORY ||--o{ MENU_ITEM : "contains"
    MENU_ITEM ||--o{ MENU_ITEM_TOPPING_MAPPING : "offers"
    OPTION_TOPPING ||--o{ MENU_ITEM_TOPPING_MAPPING : "linked via"
    MENU_ITEM ||--o{ ORDER_ITEM : "ordered in"
    MENU_ITEM ||--o{ BRANCH_MENU_STATUS : "status at"

    ORDER ||--o{ ORDER_ITEM : "contains"
    ORDER ||--o| ORDER_CANCELLATION : "cancelled by"
    ORDER ||--o{ ORDER_REFUND : "refunded by"
    ORDER_ITEM ||--o{ ORDER_ITEM_TOPPING : "customized"
    OPTION_TOPPING ||--o{ ORDER_ITEM_TOPPING : "applied in"

    CUSTOMER ||--o{ ORDER : "places"
    SHIFT_SESSION ||--o{ ORDER : "processes"
    VOUCHER ||--o{ ORDER : "discounts"
```

### **2.2. Operations, Staffing & Audit ERD**

*\[This diagram focuses on inventory management, recipe formulation for items/toppings, staff schedules, attendance tracking, and system audit logs.\]*

```mermaid
erDiagram
    STORE {
        UNIQUEIDENTIFIER id PK
        NVARCHAR(255) name
        NVARCHAR(255) address
        NVARCHAR(255) phone
        BIT is_active
        DATETIME2 created_at
    }

    USER {
        UNIQUEIDENTIFIER id PK
        NVARCHAR(255) username
        NVARCHAR(255) password_hash
        VARCHAR(50) role
        NVARCHAR(255) full_name
        BIT is_active
        NVARCHAR(255) email
        NVARCHAR(255) phone
        UNIQUEIDENTIFIER store_id FK
        NVARCHAR(255) employee_id
        INT failed_attempts
        DATETIME2 lock_expiry_at
        DATETIME2 password_last_changed_at
        DATETIME2 created_at
        DATETIME2 last_login_at
        BIT must_change_password
        NVARCHAR(255) attendance_pin
    }

    RAW_MATERIAL {
        UNIQUEIDENTIFIER id PK
        NVARCHAR(255) code
        NVARCHAR(255) name
        NVARCHAR(255) unit
        DECIMAL(18,2) suggested_min_threshold
        DECIMAL(18,2) standard_cost
        BIT is_active
        NVARCHAR(255) category
    }

    STOCK_ITEM {
        UNIQUEIDENTIFIER id PK
        UNIQUEIDENTIFIER store_id FK
        UNIQUEIDENTIFIER raw_material_id FK
        DECIMAL(18,2) current_quantity
        DECIMAL(18,2) min_alert_threshold
    }

    STOCK_TRANSACTION {
        UNIQUEIDENTIFIER id PK
        UNIQUEIDENTIFIER stock_item_id FK
        UNIQUEIDENTIFIER manager_id FK
        VARCHAR(50) transaction_type "IMPORT/EXPORT/AUDIT_ADJUSTMENT/RECIPE_DEDUCTION/PHANTOM_USAGE"
        DECIMAL(18,2) quantity
        NVARCHAR(MAX) reason
        DATETIME2 created_at
    }

    RECIPE_ITEM {
        UNIQUEIDENTIFIER id PK
        UNIQUEIDENTIFIER menu_item_id FK
        UNIQUEIDENTIFIER option_topping_id FK
        UNIQUEIDENTIFIER raw_material_id FK
        DECIMAL(18,2) quantity_required
    }

    MENU_ITEM {
        UNIQUEIDENTIFIER id PK
        UNIQUEIDENTIFIER category_id FK
        UNIQUEIDENTIFIER parent_item_id FK
        NVARCHAR(255) name
        DECIMAL(18,2) price
        NVARCHAR(MAX) description
        BIT is_active
        NVARCHAR(255) image_url
        NVARCHAR(255) barcode
        NVARCHAR(255) sku
        NVARCHAR(255) size_name
        NVARCHAR(255) abbreviation
        DATETIME2 created_at
        BIT is_deleted
    }

    OPTION_TOPPING {
        UNIQUEIDENTIFIER id PK
        NVARCHAR(255) name
        DECIMAL(18,2) price
        BIT is_active
    }

    STAFF_SCHEDULE {
        UNIQUEIDENTIFIER id PK
        UNIQUEIDENTIFIER store_id FK
        UNIQUEIDENTIFIER user_id FK
        DATE shift_date
        VARCHAR(50) shift_type
        TIME shift_start_time
        TIME shift_end_time
        NVARCHAR(255) pos_register_id
        DATETIME2 created_at
    }

    ATTENDANCE {
        UNIQUEIDENTIFIER id PK
        UNIQUEIDENTIFIER store_id FK
        UNIQUEIDENTIFIER user_id FK
        DATE shift_date
        DATETIME2 check_in_at
        DATETIME2 check_out_at
        DATETIME2 scheduled_start
        VARCHAR(50) status
        NVARCHAR(255) photo_url
    }

    AUDIT_LOG {
        UNIQUEIDENTIFIER id PK
        UNIQUEIDENTIFIER user_id FK
        VARCHAR(50) action_type
        NVARCHAR(255) entity_affected
        NVARCHAR(MAX) old_value_json
        NVARCHAR(MAX) new_value_json
        DATETIME2 created_at
    }

    SYSTEM_CONFIG {
        UNIQUEIDENTIFIER id PK
        NVARCHAR(255) config_key
        NVARCHAR(255) config_value
        NVARCHAR(255) scope
        UNIQUEIDENTIFIER store_id FK
        NVARCHAR(255) updated_by
    }

    %% Relationships
    STORE ||--o{ STOCK_ITEM : "holds"
    STORE ||--o{ SYSTEM_CONFIG : "overrides"
    STORE ||--o{ STAFF_SCHEDULE : "schedules"
    STORE ||--o{ ATTENDANCE : "tracks"

    USER ||--o{ STOCK_TRANSACTION : "performs"
    USER ||--o{ STAFF_SCHEDULE : "scheduled"
    USER ||--o{ ATTENDANCE : "logs"
    USER ||--o{ AUDIT_LOG : "triggers"

    RAW_MATERIAL ||--o{ STOCK_ITEM : "stocked as"
    RAW_MATERIAL ||--o{ RECIPE_ITEM : "consumed by"
    STOCK_ITEM ||--o{ STOCK_TRANSACTION : "recorded in"

    MENU_ITEM ||--o{ RECIPE_ITEM : "formulated"
    OPTION_TOPPING ||--o{ RECIPE_ITEM : "formulated"
```

***Table Descriptions***

| No | Table | Description |
| :---- | :---- | :---- |
| 01 | users | Stores login credentials, RBAC roles, and attendance PIN for check-in/out (BR-93). attendance_pin must be unique per store (store_id). Key definitions: PK is id (UUID); FK is store_id → stores(id) |
| 02 | categories | Main food and beverage product groupings (e.g., Coffee, Tea, Pastry). Used to organize the menu catalog chain-wide. Key definitions: PK is id (UUID) |
| 03 | menu_items | Individual beverage/food catalog listings with pricing, barcodes, chain-wide active status, and image references. Soft-delete supported via is_deleted flag. Key definitions: PK is id (UUID); FK is category_id → categories(id) |
| 04 | branch_menu_status | Per-branch item availability toggle. Allows Store Manager to temporarily disable items locally without affecting other branches. Tracks last_updated_by/last_updated_at. Key definitions: PK is id (UUID); UNIQUE (store_id, menu_item_id); FK is store_id → stores(id), menu_item_id → menu_items(id) |
| 05 | option_toppings | Global customizable add-ons (e.g., Extra Shot, Oat Milk, Tapioca Pearls), shared across menu items via menu_item_topping_mappings (BR-29). Price may be 0 (e.g. "No Ice"); a topping may carry its own recipe (BR-65). Key definitions: PK is id (UUID) — no direct menu_item FK (toppings are chain-wide global) |
| 06 | customers | Loyalty membership registry tracking points balance. Includes PDPA consent timestamp (consent_at) and consent version (consent_version) (BR-71). Key definitions: PK is id (UUID) |
| 07 | shift_sessions | POS cashier work session records including opening/closing cash float, discrepancy, and shift status (OPEN / CLOSED). Key definitions: PK is id (UUID); FK is store_id → stores(id), user_id → users(id) |
| 08 | orders | Sales transaction records linking customer, shift, voucher, payment status, and fulfillment status (7 states: PENDING / PREPARING / HOLD / READY / COMPLETED / CANCELLED / ABANDONED). Key definitions: PK is id (UUID); FK is store_id → stores(id), shift_session_id → shift_sessions(id), customer_id → customers(id), voucher_id → vouchers(id) |
| 09 | order_items | Line items of each order with quantity and unit price snapshot at time of sale. Key definitions: PK is id (UUID); FK is order_id → orders(id), menu_item_id → menu_items(id) |
| 10 | order_item_toppings | Toppings applied to specific order line items, with quantity and price snapshot at time of sale. Key definitions: PK is id (UUID); FK is order_item_id → order_items(id), topping_id → option_toppings(id) |
| 11 | order_cancellations | Immutable audit log for PENDING order cancellations (BR-05). Records the cashier, reason code, and notes. One record per cancelled order. Key definitions: PK is id (UUID); FK is order_id → orders(id) UNIQUE, cashier_id → users(id) |
| 12 | order_refunds | Store-Manager authorized refund/comp audit log for post-PENDING complaints (UC-75, BR-67). Supports REFUND and COMP_REMAKE types, partial refund amounts. Key definitions: PK is id (UUID); FK is order_id → orders(id), sm_id → users(id), cashier_id → users(id), shift_session_id → shift_sessions(id) |
| 13 | raw_materials | Chain-wide master catalog of ingredients/materials owned exclusively by Business Admin (UC-74). The canonical source for recipe formulations and branch stock dropdowns. Supports soft-delete. Key definitions: PK is id (UUID) |
| 14 | stock_items | Per-branch on-hand quantity of a master raw material. Scoped to one store. Unique constraint on (store_id, raw_material_id). Key definitions: PK is id (UUID); FK is store_id → stores(id), raw_material_id → raw_materials(id) |
| 15 | stock_transactions | Historical ledger of all stock movements: IMPORT, EXPORT, AUDIT_ADJUSTMENT, RECIPE_DEDUCTION, PHANTOM_USAGE. System recipe deductions and phantom usage transactions have null manager_id. Key definitions: PK is id (UUID); FK is stock_item_id → stock_items(id), manager_id → users(id) |
| 16 | vouchers | Promotional discount codes with type (PERCENTAGE / FIXED_AMOUNT), usage limits per customer and total, validity dates, and cap amount for percentage discounts. Key definitions: PK is id (UUID) |
| 17 | recipe_items | Ingredient formula defining how much of a raw material is consumed to produce one unit of a menu item or topping. Exactly one of menu_item_id or option_topping_id is non-null. Key definitions: PK is id (UUID); FK is menu_item_id → menu_items(id), option_topping_id → option_toppings(id), raw_material_id → raw_materials(id) |
| 18 | stores | Physical branch locations with name, address, phone, and active status. Root entity that many other entities reference. Key definitions: PK is id (UUID) |
| 19 | staff_schedules | Assigned employee shift blocks (MORNING / AFTERNOON / FULL_DAY) per date and branch. Includes shift_start_time, shift_end_time, and optional pos_register_id allocation. Key definitions: PK is id (UUID); FK is store_id → stores(id), user_id → users(id) |
| 20 | attendance_logs | Employee clock-in/out records. At check-in, system snapshots scheduled_start (shift start time) to calculate lateness dynamically at the reporting layer; lateness is not stored in the database. Mandatory check-in photo_url stored; the URL is nulled by the 90-day PDPA purge (BR-72) while the row is retained for payroll. One row per attendance pairing (check_in_at + check_out_at). Key definitions: PK is id (UUID); FK is store_id → stores(id), user_id → users(id) |
| 21 | audit_logs | Immutable security event log (append-only, no UPDATE / DELETE permitted). Records price changes, voucher mutations, user account changes, checkout voucher/point usage. Key definitions: PK is id (UUID); FK is user_id → users(id) |
| 22 | system_configs | Central (scope GLOBAL) and per-branch (scope BRANCH) runtime parameters as key/value rows: VAT_RATE, LOYALTY_* , MAX_ACTIVE_BRANCHES, HQ_MFA_REQUIRED, CANCEL_REFUND_ALERT_THRESHOLD, VietQR credentials, branch timezone/hardware overrides (UC-30/UC-42). Key definitions: PK is id (UUID); FK is store_id → stores(id) (null for GLOBAL scope) |
| 23 | menu_item_topping_mappings | Join table linking global option_toppings to the menu_items that offer them (many-to-many, BR-29). Key definitions: PK is id (UUID); UNIQUE (menu_item_id, option_topping_id); FK is menu_item_id → menu_items(id), option_topping_id → option_toppings(id) |
