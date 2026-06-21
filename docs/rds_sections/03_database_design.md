## **2\. Database Design**

*\[The database design follows the entity relationships defined in the SRS (§3.1.5 / §3.1.6). The system uses `SQL Server` with ACID transactions and Unicode support (`NVARCHAR`). All primary keys use `UUID` (`VARCHAR(36)`). The diagrams below show the entity relationships with full column definitions, followed by the table descriptions.\]*

### **2.1. Core Sales & POS ERD**

*\[This diagram focuses on sales flows at the POS terminal, Menu information, Customers, Shift sessions, and Promotions.\]*

```mermaid
erDiagram
    STORE {
        uuid id PK
        string name
        string address
        string phone
        boolean is_active
        datetime created_at
    }

    USER {
        uuid id PK
        string username
        string password_hash
        enum role
        string full_name
        boolean is_active
        string email
        string phone
        uuid store_id FK
        datetime created_at
        datetime last_login_at
        boolean must_change_password
        string attendance_pin
    }

    CATEGORY {
        uuid id PK
        string name
        text description
        boolean is_active
    }

    MENU_ITEM {
        uuid id PK
        uuid category_id FK
        string name
        decimal price
        text description
        boolean is_active
        string image_url
        string barcode
        string abbreviation
        datetime created_at
        boolean is_deleted
    }

    BRANCH_MENU_STATUS {
        uuid store_id PK
        uuid menu_item_id PK
        boolean is_available
    }

    OPTION_TOPPING {
        uuid id PK
        uuid menu_item_id FK
        string name
        decimal price
        boolean is_active
    }

    CUSTOMER {
        uuid id PK
        string phone
        string full_name
        int points
        string email
        datetime created_at
        datetime consent_at
        string consent_version
    }

    SHIFT_SESSION {
        uuid id PK
        uuid store_id FK
        uuid user_id FK
        datetime start_time
        datetime end_time
        decimal starting_cash
        decimal ending_cash
        enum status
        string pos_register_id
    }

    ORDER {
        uuid id PK
        uuid store_id FK
        string order_number
        uuid shift_session_id FK
        uuid customer_id FK
        uuid voucher_id FK
        enum order_type
        decimal subtotal
        decimal discount
        decimal tax_amount
        decimal total
        enum payment_method
        enum payment_status
        enum order_status
        datetime created_at
    }

    ORDER_ITEM {
        uuid id PK
        uuid order_id FK
        uuid menu_item_id FK
        int quantity
        decimal unit_price
    }

    ORDER_ITEM_TOPPING {
        uuid id PK
        uuid order_item_id FK
        uuid topping_id FK
        int quantity
        decimal unit_price
    }

    ORDER_CANCELLATION {
        uuid id PK
        uuid order_id FK
        uuid cashier_id FK
        string reason
        text notes
        datetime created_at
    }

    ORDER_REFUND {
        uuid id PK
        uuid order_id FK
        uuid sm_id FK
        uuid cashier_id FK
        uuid shift_session_id FK
        enum refund_type
        decimal amount
        string reason
        text notes
        datetime created_at
    }

    VOUCHER {
        uuid id PK
        string code
        enum discount_type
        decimal discount_value
        decimal min_order_value
        datetime start_date
        datetime end_date
        boolean is_active
        int usage_limit_per_customer
        int total_usage_count
        int max_total_uses
        decimal max_discount_amount
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
    MENU_ITEM ||--o{ OPTION_TOPPING : "has"
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
        uuid id PK
        string name
        string address
        string phone
        boolean is_active
        datetime created_at
    }

    USER {
        uuid id PK
        string username
        string password_hash
        enum role
        string full_name
        boolean is_active
        string email
        string phone
        uuid store_id FK
        datetime created_at
        datetime last_login_at
        boolean must_change_password
        string attendance_pin
    }

    RAW_MATERIAL {
        uuid id PK
        string code
        string name
        string unit
        decimal suggested_min_threshold
        decimal standard_cost
        boolean is_active
        enum category
    }

    STOCK_ITEM {
        uuid id PK
        uuid store_id FK
        uuid raw_material_id FK
        decimal current_quantity
        decimal min_alert_threshold
    }

    STOCK_TRANSACTION {
        uuid id PK
        uuid stock_item_id FK
        uuid manager_id FK
        enum transaction_type "IMPORT/EXPORT/AUDIT_ADJUSTMENT/RECIPE_DEDUCTION/PHANTOM_USAGE"
        decimal quantity
        text reason
        datetime created_at
    }

    RECIPE_ITEM {
        uuid id PK
        uuid menu_item_id FK
        uuid option_topping_id FK
        uuid raw_material_id FK
        decimal quantity_required
    }

    MENU_ITEM {
        uuid id PK
        uuid category_id FK
        string name
        decimal price
        text description
        boolean is_active
        string image_url
        string barcode
        string abbreviation
        datetime created_at
        boolean is_deleted
    }

    OPTION_TOPPING {
        uuid id PK
        uuid menu_item_id FK
        string name
        decimal price
        boolean is_active
    }

    STAFF_SCHEDULE {
        uuid id PK
        uuid store_id FK
        uuid user_id FK
        date shift_date
        enum shift_type
        time shift_start_time
        time shift_end_time
        string pos_register_id
        datetime created_at
    }

    ATTENDANCE {
        uuid id PK
        uuid store_id FK
        uuid user_id FK
        date shift_date
        datetime check_in_at
        datetime check_out_at
        datetime scheduled_start
        enum status
        string photo_url
    }

    AUDIT_LOG {
        uuid id PK
        uuid user_id FK
        enum action_type
        string entity_affected
        text old_value_json
        text new_value_json
        datetime created_at
    }

    %% Relationships
    STORE ||--o{ STOCK_ITEM : "holds"
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
| 04 | branch_menu_status | Per-branch item availability toggle. Allows Store Manager to temporarily disable items locally without affecting other branches. Key definitions: PK is (store_id, menu_item_id) — composite; FK is store_id → stores(id), menu_item_id → menu_items(id) |
| 05 | option_toppings | Customizable add-ons for menu items (e.g., Extra Shot, Oat Milk, Tapioca Pearls). Each topping has a price and may have a recipe formula. Key definitions: PK is id (UUID); FK is menu_item_id → menu_items(id) |
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
| 20 | attendance_logs | Employee clock-in/out records. At check-in, system snapshots scheduled_start (shift start time) to calculate lateness dynamically at the reporting layer; lateness is not stored in the database. Mandatory check-in photo_path stored server-side. PDPA: auto-purged after 90 days (BR-72). Key definitions: PK is id (UUID); FK is store_id → stores(id), user_id → users(id) |
| 21 | audit_logs | Immutable security event log (append-only, no UPDATE / DELETE permitted). Records price changes, voucher mutations, user account changes, checkout voucher/point usage. Key definitions: PK is id (UUID); FK is user_id → users(id) |
