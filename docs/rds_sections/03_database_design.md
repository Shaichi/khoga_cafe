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
        DECIMAL(18_2) price
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
        DECIMAL(18_2) price
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
        DECIMAL(18_2) starting_cash
        DECIMAL(18_2) ending_cash
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
        DECIMAL(18_2) subtotal
        DECIMAL(18_2) discount
        DECIMAL(18_2) tax_amount
        DECIMAL(18_2) total
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
        DECIMAL(18_2) unit_price
    }

    ORDER_ITEM_TOPPING {
        UNIQUEIDENTIFIER id PK
        UNIQUEIDENTIFIER order_item_id FK
        UNIQUEIDENTIFIER topping_id FK
        INT quantity
        DECIMAL(18_2) unit_price
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
        DECIMAL(18_2) amount
        NVARCHAR(255) reason
        NVARCHAR(MAX) notes
        DATETIME2 created_at
    }

    VOUCHER {
        UNIQUEIDENTIFIER id PK
        NVARCHAR(255) code
        VARCHAR(50) discount_type
        DECIMAL(18_2) discount_value
        DECIMAL(18_2) min_order_value
        DATETIME2 start_date
        DATETIME2 end_date
        BIT is_active
        INT usage_limit_per_customer
        INT total_usage_count
        INT max_total_uses
        DECIMAL(18_2) max_discount_amount
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
        DECIMAL(18_2) suggested_min_threshold
        DECIMAL(18_2) standard_cost
        BIT is_active
        NVARCHAR(255) category
    }

    STOCK_ITEM {
        UNIQUEIDENTIFIER id PK
        UNIQUEIDENTIFIER store_id FK
        UNIQUEIDENTIFIER raw_material_id FK
        DECIMAL(18_2) current_quantity
        DECIMAL(18_2) min_alert_threshold
    }

    STOCK_TRANSACTION {
        UNIQUEIDENTIFIER id PK
        UNIQUEIDENTIFIER stock_item_id FK
        UNIQUEIDENTIFIER manager_id FK
        VARCHAR(50) transaction_type "IMPORT/EXPORT/AUDIT_ADJUSTMENT/RECIPE_DEDUCTION/PHANTOM_USAGE"
        DECIMAL(18_2) quantity
        NVARCHAR(MAX) reason
        DATETIME2 created_at
    }

    RECIPE_ITEM {
        UNIQUEIDENTIFIER id PK
        UNIQUEIDENTIFIER menu_item_id FK
        UNIQUEIDENTIFIER option_topping_id FK
        UNIQUEIDENTIFIER raw_material_id FK
        DECIMAL(18_2) quantity_required
    }

    MENU_ITEM {
        UNIQUEIDENTIFIER id PK
        UNIQUEIDENTIFIER category_id FK
        UNIQUEIDENTIFIER parent_item_id FK
        NVARCHAR(255) name
        DECIMAL(18_2) price
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
        DECIMAL(18_2) price
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

### **2.3. Table Descriptions**

*\[The table below summarizes the purpose, primary keys, and foreign keys for each of the 23 tables in the database. Every table also inherits an `updated_at DATETIME2` column from `BaseEntity` (JPA auditing).\]*

| No | Table | Description |
|:---:|---|---|
| 01 | **stores** | Physical coffee shop branch locations.<br>- **id**: Primary key (UUID).<br>- **name**: Name of the branch.<br>- **address**: Physical address of the branch.<br>- **phone**: Contact phone number.<br>- **is_active**: Active status flag.<br>- **created_at**: Record creation timestamp. |
| 02 | **users** | Employee accounts with login credentials, RBAC roles, and attendance PIN for check-in/out.<br>- **id**: Primary key (UUID).<br>- **username**: Login username.<br>- **password_hash**: Hashed password.<br>- **role**: User role (e.g., Cashier, Manager).<br>- **full_name**: Full name of the user.<br>- **is_active**: Active status flag.<br>- **email**: Email address.<br>- **phone**: Phone number.<br>- **store_id**: FK to stores.<br>- **employee_id**: Internal employee ID.<br>- **failed_attempts**: Failed login attempts.<br>- **lock_expiry_at**: Account lockout expiry.<br>- **password_last_changed_at**: Last password change time.<br>- **created_at**: Creation timestamp.<br>- **last_login_at**: Last login timestamp.<br>- **must_change_password**: Flag to force password change.<br>- **attendance_pin**: PIN for check-in/out. |
| 03 | **categories** | Main food and beverage product groupings (e.g., Coffee, Tea, Pastry).<br>- **id**: Primary key (UUID).<br>- **name**: Category name.<br>- **description**: Category description.<br>- **is_active**: Active status flag. |
| 04 | **menu_items** | Individual beverage/food catalog entries with pricing, barcodes, and chain-wide status.<br>- **id**: Primary key (UUID).<br>- **category_id**: FK to categories.<br>- **parent_item_id**: FK to parent menu_items.<br>- **name**: Item name.<br>- **price**: Base price.<br>- **description**: Item description.<br>- **is_active**: Active status flag.<br>- **image_url**: Image URL.<br>- **barcode**: Item barcode.<br>- **sku**: Stock Keeping Unit.<br>- **size_name**: Size option (e.g., M, L).<br>- **abbreviation**: Short name.<br>- **created_at**: Creation timestamp.<br>- **is_deleted**: Soft delete flag. |
| 05 | **branch_menu_status** | Per-branch item availability toggle.<br>- **store_id**: PK/FK to stores.<br>- **menu_item_id**: PK/FK to menu_items.<br>- **is_available**: Availability flag at this branch. |
| 06 | **option_toppings** | Global add-ons (e.g., Extra Shot, Oat Milk) shared across menu items.<br>- **id**: Primary key (UUID).<br>- **name**: Topping name.<br>- **price**: Additional price.<br>- **is_active**: Active status flag. |
| 07 | **menu_item_topping_mappings** | Join table linking global option_toppings to menu_items.<br>- **id**: Primary key (UUID).<br>- **menu_item_id**: FK to menu_items.<br>- **option_topping_id**: FK to option_toppings. |
| 08 | **customers** | Loyalty membership registry tracking points balance and PDPA consent.<br>- **id**: Primary key (UUID).<br>- **phone**: Customer phone number.<br>- **full_name**: Customer full name.<br>- **points**: Loyalty points balance.<br>- **email**: Customer email.<br>- **birth_date**: Customer date of birth.<br>- **is_active**: Active status flag.<br>- **created_at**: Creation timestamp.<br>- **consent_at**: PDPA consent timestamp.<br>- **consent_version**: PDPA consent version. |
| 09 | **shift_sessions** | POS cashier work session records.<br>- **id**: Primary key (UUID).<br>- **store_id**: FK to stores.<br>- **user_id**: FK to users (cashier).<br>- **start_time**: Shift start timestamp.<br>- **end_time**: Shift end timestamp.<br>- **starting_cash**: Cash in drawer at start.<br>- **ending_cash**: Cash in drawer at end.<br>- **status**: Shift status.<br>- **pos_register_id**: POS terminal identifier. |
| 10 | **orders** | Sales transaction records following a strict 7-state machine.<br>- **id**: Primary key (UUID).<br>- **store_id**: FK to stores.<br>- **order_number**: Unique order reference.<br>- **shift_session_id**: FK to shift_sessions.<br>- **customer_id**: FK to customers.<br>- **voucher_id**: FK to vouchers.<br>- **order_type**: Dine-in, Takeaway, etc.<br>- **subtotal**: Order subtotal.<br>- **discount**: Total discount applied.<br>- **tax_amount**: Total tax applied.<br>- **total**: Final order total.<br>- **payment_method**: Cash, Card, etc.<br>- **payment_status**: Pending, Paid, etc.<br>- **status**: Order status (state machine).<br>- **created_at**: Creation timestamp. |
| 11 | **order_items** | Line items within each order with snapshot pricing.<br>- **id**: Primary key (UUID).<br>- **order_id**: FK to orders.<br>- **menu_item_id**: FK to menu_items.<br>- **quantity**: Quantity ordered.<br>- **unit_price**: Snapshot price per unit. |
| 12 | **order_item_toppings** | Toppings applied to specific order line items with snapshot pricing.<br>- **id**: Primary key (UUID).<br>- **order_item_id**: FK to order_items.<br>- **topping_id**: FK to option_toppings.<br>- **quantity**: Quantity applied.<br>- **unit_price**: Snapshot price per topping. |
| 13 | **order_cancellations** | Immutable audit log for PENDING-state order cancellations.<br>- **id**: Primary key (UUID).<br>- **order_id**: FK to orders.<br>- **cashier_id**: FK to users (cashier).<br>- **reason**: Reason for cancellation.<br>- **notes**: Additional notes.<br>- **created_at**: Cancellation timestamp. |
| 14 | **order_refunds** | Store-Manager authorized refund/comp audit log for post-PENDING complaints.<br>- **id**: Primary key (UUID).<br>- **order_id**: FK to orders.<br>- **sm_id**: FK to users (store manager).<br>- **cashier_id**: FK to users (cashier).<br>- **shift_session_id**: FK to shift_sessions.<br>- **refund_type**: Type of refund.<br>- **amount**: Refund amount.<br>- **reason**: Reason for refund.<br>- **notes**: Additional notes.<br>- **created_at**: Refund timestamp. |
| 15 | **vouchers** | Promotional discount codes with usage limits.<br>- **id**: Primary key (UUID).<br>- **code**: Voucher code.<br>- **discount_type**: Percentage or Fixed.<br>- **discount_value**: Discount amount/percent.<br>- **min_order_value**: Minimum required subtotal.<br>- **start_date**: Validity start.<br>- **end_date**: Validity end.<br>- **is_active**: Active status flag.<br>- **usage_limit_per_customer**: Max uses per user.<br>- **total_usage_count**: Current usage count.<br>- **max_total_uses**: Global max uses limit.<br>- **max_discount_amount**: Maximum discount cap. |
| 16 | **raw_materials** | Chain-wide master catalog of ingredients/materials.<br>- **id**: Primary key (UUID).<br>- **code**: Material code.<br>- **name**: Material name.<br>- **unit**: Unit of measurement.<br>- **suggested_min_threshold**: Suggested minimum stock.<br>- **standard_cost**: Standard cost.<br>- **is_active**: Active status flag.<br>- **category**: Material category. |
| 17 | **stock_items** | Per-branch on-hand quantity of a master raw material.<br>- **id**: Primary key (UUID).<br>- **store_id**: FK to stores.<br>- **raw_material_id**: FK to raw_materials.<br>- **current_quantity**: Current stock level.<br>- **min_alert_threshold**: Minimum alert threshold. |
| 18 | **stock_transactions** | Immutable historical ledger (append-only) of all stock movements.<br>- **id**: Primary key (UUID).<br>- **stock_item_id**: FK to stock_items.<br>- **manager_id**: FK to users (manager).<br>- **transaction_type**: IMPORT/EXPORT/etc.<br>- **quantity**: Transaction quantity.<br>- **reason**: Reason for transaction.<br>- **created_at**: Transaction timestamp. |
| 19 | **recipe_items** | Ingredient formula defining raw material consumption for items/toppings.<br>- **id**: Primary key (UUID).<br>- **menu_item_id**: FK to menu_items.<br>- **option_topping_id**: FK to option_toppings.<br>- **raw_material_id**: FK to raw_materials.<br>- **quantity_required**: Required quantity per unit. |
| 20 | **staff_schedules** | Assigned employee shift blocks per date and branch.<br>- **id**: Primary key (UUID).<br>- **store_id**: FK to stores.<br>- **user_id**: FK to users (employee).<br>- **shift_date**: Scheduled date.<br>- **shift_type**: Type of shift.<br>- **shift_start_time**: Scheduled start time.<br>- **shift_end_time**: Scheduled end time.<br>- **pos_register_id**: Assigned POS terminal.<br>- **created_at**: Creation timestamp. |
| 21 | **attendance_logs** | Employee clock-in/out records with snapshot scheduling.<br>- **id**: Primary key (UUID).<br>- **store_id**: FK to stores.<br>- **user_id**: FK to users (employee).<br>- **shift_date**: Associated shift date.<br>- **check_in_at**: Clock-in timestamp.<br>- **check_out_at**: Clock-out timestamp.<br>- **scheduled_start**: Snapshot of scheduled start.<br>- **status**: Attendance status.<br>- **photo_url**: Snapshot photo URL. |
| 22 | **audit_logs** | Immutable security event log for configuration and access changes.<br>- **id**: Primary key (UUID).<br>- **user_id**: FK to users.<br>- **action_type**: Type of action.<br>- **entity_affected**: Affected entity name.<br>- **old_value_json**: Previous state.<br>- **new_value_json**: New state.<br>- **created_at**: Event timestamp. |
| 23 | **system_configs** | Central and per-branch runtime configuration.<br>- **id**: Primary key (UUID).<br>- **config_key**: Configuration key.<br>- **config_value**: Configuration value.<br>- **scope**: Scope of config (Global/Branch).<br>- **store_id**: FK to stores.<br>- **updated_by**: User who last updated. |
