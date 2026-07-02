-- V1 — Baseline schema (23+ tables) for Khoga Coffee Shop.
--
-- GENERATED from the Hibernate metadata (SQLServerDialect) of the @Entity classes in
-- com.khoga.common.model, so it reproduces EXACTLY the schema that ddl-auto=update used to build.
-- This is what lets prod run with spring.jpa.hibernate.ddl-auto=validate against a Flyway-built DB.
--
-- IMPORTANT: table/column names use Hibernate's implicit naming strategy (e.g. "categorys",
-- "branchmenustatuss"). Do NOT "tidy" them — Hibernate `validate` compares against these exact names,
-- so any rename here must be matched by a @Table/@Column on the entity or the context fails to start.
-- To evolve the schema, add V2__*.sql / V3__*.sql (never edit this file once it has been applied).

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------
create table attendancelogs (pending_verification bit, shift_date date, check_in_at datetime2(7), check_out_at datetime2(7), created_at datetime2(7) not null, scheduled_start datetime2(7), updated_at datetime2(7), id uniqueidentifier not null, store_id uniqueidentifier, user_id uniqueidentifier, photo_url varchar(255), status varchar(255) check ((status in ('PRESENT','LATE','ABSENT'))), primary key (id));
create table auditlogs (created_at datetime2(7) not null, updated_at datetime2(7), id uniqueidentifier not null, user_id uniqueidentifier, action_type varchar(255) check ((action_type in ('CREATE','UPDATE','DELETE','PRICE_UPDATE','POINT_ADJUSTMENT','CONFIG_UPDATE','DEACTIVATE'))), entity_affected varchar(255), new_value_json varchar(255), old_value_json varchar(255), primary key (id));
create table branchmenustatuss (is_available bit, created_at datetime2(7) not null, updated_at datetime2(7), id uniqueidentifier not null, menu_item_id uniqueidentifier, store_id uniqueidentifier, primary key (id));
create table categorys (is_active bit, created_at datetime2(7) not null, updated_at datetime2(7), id uniqueidentifier not null, description varchar(255), name varchar(255), primary key (id));
create table customers (birth_date date, is_active bit, points int, consent_at datetime2(7), created_at datetime2(7) not null, updated_at datetime2(7), id uniqueidentifier not null, consent_version varchar(255), email varchar(255), full_name varchar(255), phone varchar(255), primary key (id));
create table menu_item_topping_mappings (created_at datetime2(7) not null, updated_at datetime2(7), id uniqueidentifier not null, menu_item_id uniqueidentifier not null, option_topping_id uniqueidentifier not null, primary key (id));
create table menuitems (is_active bit, is_deleted bit, price numeric(38,2), created_at datetime2(7) not null, updated_at datetime2(7), category_id uniqueidentifier, id uniqueidentifier not null, parent_item_id uniqueidentifier, abbreviation varchar(255), barcode varchar(255), description varchar(255), image_url varchar(255), name varchar(255), size_name varchar(255), sku varchar(255), primary key (id));
create table optiontoppings (is_active bit, price numeric(38,2), created_at datetime2(7) not null, updated_at datetime2(7), id uniqueidentifier not null, name varchar(255), primary key (id));
create table ordercancellations (created_at datetime2(7) not null, updated_at datetime2(7), cashier_id uniqueidentifier, id uniqueidentifier not null, order_id uniqueidentifier, notes varchar(255), reason varchar(255), primary key (id));
create table orderitems (quantity int, unit_price numeric(38,2), created_at datetime2(7) not null, updated_at datetime2(7), id uniqueidentifier not null, menu_item_id uniqueidentifier, order_id uniqueidentifier, primary key (id));
create table orderitemtoppings (quantity int, unit_price numeric(38,2), created_at datetime2(7) not null, updated_at datetime2(7), id uniqueidentifier not null, order_item_id uniqueidentifier, topping_id uniqueidentifier, primary key (id));
create table orderrefunds (amount numeric(38,2), created_at datetime2(7) not null, updated_at datetime2(7), cashier_id uniqueidentifier, id uniqueidentifier not null, order_id uniqueidentifier, shift_session_id uniqueidentifier, sm_id uniqueidentifier, notes varchar(255), reason varchar(255), refund_type varchar(255) check ((refund_type in ('REFUND','COMP_REMAKE'))), primary key (id));
create table orders (discount numeric(38,2), points_earned int, points_redeemed int, subtotal numeric(38,2), tax_amount numeric(38,2), total numeric(38,2), created_at datetime2(7) not null, ready_at datetime2(7), updated_at datetime2(7), customer_id uniqueidentifier, id uniqueidentifier not null, shift_session_id uniqueidentifier, store_id uniqueidentifier, voucher_id uniqueidentifier, order_number varchar(255), order_type varchar(255) check ((order_type in ('DINE_IN','TAKEAWAY','DELIVERY'))), payment_method varchar(255) check ((payment_method in ('CASH','CARD','VIETQR','LOYALTY_POINTS'))), payment_status varchar(255) check ((payment_status in ('UNPAID','PAID','REFUNDED'))), status varchar(255) check ((status in ('PENDING','PREPARING','HOLD','READY','COMPLETED','CANCELLED','ABANDONED'))), transaction_ref varchar(255), primary key (id));
create table otp_tokens (attempts int not null, code varchar(6) not null, expires_at datetime2(7) not null, user_id uniqueidentifier not null, id varchar(255) not null, primary key (id));
create table rawmaterials (is_active bit, standard_cost numeric(38,2), suggested_min_threshold numeric(38,2), created_at datetime2(7) not null, updated_at datetime2(7), id uniqueidentifier not null, category varchar(255), code varchar(255), name varchar(255), unit varchar(255), primary key (id));
create table recipeitems (quantity_required numeric(38,2), created_at datetime2(7) not null, updated_at datetime2(7), id uniqueidentifier not null, menu_item_id uniqueidentifier, option_topping_id uniqueidentifier, raw_material_id uniqueidentifier, primary key (id));
create table shiftsessions (ending_cash numeric(38,2), starting_cash numeric(38,2), created_at datetime2(7) not null, end_time datetime2(7), start_time datetime2(7), updated_at datetime2(7), id uniqueidentifier not null, store_id uniqueidentifier, user_id uniqueidentifier, pos_register_id varchar(255), status varchar(255) check ((status in ('OPEN','CLOSED'))), primary key (id));
create table staffschedules (shift_date date, shift_end_time time, shift_start_time time, created_at datetime2(7) not null, updated_at datetime2(7), id uniqueidentifier not null, store_id uniqueidentifier, user_id uniqueidentifier, pos_register_id varchar(255), shift_type varchar(255) check ((shift_type in ('MORNING','AFTERNOON','FULL_DAY'))), primary key (id));
create table stockitems (current_quantity numeric(38,2), min_alert_threshold numeric(38,2), created_at datetime2(7) not null, updated_at datetime2(7), id uniqueidentifier not null, raw_material_id uniqueidentifier, store_id uniqueidentifier, primary key (id));
create table stocktransactions (quantity numeric(38,2), quantity_after numeric(38,2), quantity_before numeric(38,2), created_at datetime2(7) not null, updated_at datetime2(7), id uniqueidentifier not null, manager_id uniqueidentifier, stock_item_id uniqueidentifier, reason varchar(255), transaction_type varchar(255) check ((transaction_type in ('IMPORT','EXPORT','AUDIT_ADJUSTMENT','RECIPE_DEDUCTION','PHANTOM_USAGE'))), primary key (id));
create table stores (is_active bit, created_at datetime2(7) not null, updated_at datetime2(7), id uniqueidentifier not null, address varchar(255), name varchar(255), phone varchar(255), primary key (id));
create table systemconfigs (created_at datetime2(7) not null, updated_at datetime2(7), id uniqueidentifier not null, store_id uniqueidentifier, config_key varchar(255), config_value varchar(255), scope varchar(255), updated_by varchar(255), primary key (id));
create table users (failed_attempts int, is_active bit, must_change_password bit, pin_failed_attempts int, token_version int, created_at datetime2(7) not null, last_active_at datetime2(7), last_login_at datetime2(7), last_logout_at datetime2(7), lock_expiry_at datetime2(7), password_last_changed_at datetime2(7), pin_locked_until datetime2(7), updated_at datetime2(7), id uniqueidentifier not null, store_id uniqueidentifier, attendance_pin varchar(255), email varchar(255), employee_id varchar(255), full_name varchar(255), password_hash varchar(255), phone varchar(255), role varchar(255) check ((role in ('CASHIER','BARISTA','STORE_MANAGER','CEOVIEWER','BUSINESSADMIN','SSADMIN'))), username varchar(255), primary key (id));
create table vouchers (discount_value numeric(38,2), is_active bit, max_discount_amount numeric(38,2), max_total_uses int, min_order_value numeric(38,2), total_usage_count int, usage_limit_per_customer int, created_at datetime2(7) not null, end_date datetime2(7), start_date datetime2(7), updated_at datetime2(7), id uniqueidentifier not null, description varchar(250), code varchar(255), discount_type varchar(255) check ((discount_type in ('PERCENTAGE','FIXED_AMOUNT'))), primary key (id));

-- ---------------------------------------------------------------------------
-- Indexes & unique constraints
-- ---------------------------------------------------------------------------
create index idx_audit_entity_created on auditlogs (entity_affected, created_at);
create index idx_audit_user_created on auditlogs (user_id, created_at);
create unique nonclustered index UK2n3utqbhldm6llbsh086b3jnd on branchmenustatuss (store_id, menu_item_id) where store_id is not null and menu_item_id is not null;
alter table menu_item_topping_mappings add constraint UKgxp6b1t0ihbdiyuufoyh275qf unique (menu_item_id, option_topping_id);
create unique nonclustered index UKdj6m8pea0ap4vws83acnv41q7 on ordercancellations (order_id) where order_id is not null;
create index idx_orders_store_created on orders (store_id, created_at);
create index idx_orders_status_created on orders (status, created_at);
create index idx_orders_shift on orders (shift_session_id);
create unique nonclustered index UKfghpxmrpibvq9qsrb0mb8emlg on stockitems (store_id, raw_material_id) where store_id is not null and raw_material_id is not null;
create index idx_stocktx_item_created on stocktransactions (stock_item_id, created_at);

-- ---------------------------------------------------------------------------
-- Foreign keys
-- ---------------------------------------------------------------------------
alter table attendancelogs add constraint FKklp8flfj9m0jeoenifbh2865n foreign key (store_id) references stores;
alter table attendancelogs add constraint FKdi77de07isu1oy3ay9dv6ksd5 foreign key (user_id) references users;
alter table auditlogs add constraint FKs9wc10a24mw0w3ifnpw89w8xj foreign key (user_id) references users;
alter table branchmenustatuss add constraint FK8gpnpvyq5c9eomxpwtxqs51ji foreign key (menu_item_id) references menuitems;
alter table branchmenustatuss add constraint FKeusafmmp9xxd3kdq1sig85msu foreign key (store_id) references stores;
alter table menu_item_topping_mappings add constraint FK740b7qmmaf3x4l04pqwnjyp4l foreign key (menu_item_id) references menuitems;
alter table menu_item_topping_mappings add constraint FKeylvnaimad64x0q6jxverdl7h foreign key (option_topping_id) references optiontoppings;
alter table menuitems add constraint FKbheguekf0o1e2nix2oglj39v1 foreign key (category_id) references categorys;
alter table ordercancellations add constraint FK98w0wandhyw5skgoppquyk4g8 foreign key (cashier_id) references users;
alter table ordercancellations add constraint FK2ihyiucs5orw3c23k2el0rsay foreign key (order_id) references orders;
alter table orderitems add constraint FK9l3vjwl6lb19fva1yi485xg2q foreign key (menu_item_id) references menuitems;
alter table orderitems add constraint FKm3mp87f5ygbbfuqfdhc09y9a foreign key (order_id) references orders;
alter table orderitemtoppings add constraint FKnamk2nst81s0cnc3hasqkedtb foreign key (order_item_id) references orderitems;
alter table orderitemtoppings add constraint FK9qkare8f7s43uyjda1ue3lha2 foreign key (topping_id) references optiontoppings;
alter table orderrefunds add constraint FKkuxe6hkurfd802g2onbk9lb35 foreign key (cashier_id) references users;
alter table orderrefunds add constraint FKnjsyp5e5rnm2rt3kev229nlxe foreign key (order_id) references orders;
alter table orderrefunds add constraint FK9uuhp3j1gy90yh61xsfmws5fs foreign key (shift_session_id) references shiftsessions;
alter table orderrefunds add constraint FKyrfyikqt642asihvxvc8k7io foreign key (sm_id) references users;
alter table orders add constraint FKpxtb8awmi0dk6smoh2vp1litg foreign key (customer_id) references customers;
alter table orders add constraint FKlco5j8mdqr1tq3kljvi6ik3gn foreign key (shift_session_id) references shiftsessions;
alter table orders add constraint FKnqkwhwveegs6ne9ra90y1gq0e foreign key (store_id) references stores;
alter table orders add constraint FKdimvsocblb17f45ikjr6xn1wj foreign key (voucher_id) references vouchers;
alter table recipeitems add constraint FK9vddm9q3meqjo87un8p6yw4jt foreign key (menu_item_id) references menuitems;
alter table recipeitems add constraint FKopfed8w875wxnedju0m7h90q8 foreign key (option_topping_id) references optiontoppings;
alter table recipeitems add constraint FK55dhjdpqfc22wwi56bnc5d4ud foreign key (raw_material_id) references rawmaterials;
alter table shiftsessions add constraint FKd01d5oxlv8knnpb2fp4gcummw foreign key (store_id) references stores;
alter table shiftsessions add constraint FK9c5me1pf85ioena5dmjkqygqc foreign key (user_id) references users;
alter table staffschedules add constraint FKeteiir0sw52f91wmkhxaxfgti foreign key (store_id) references stores;
alter table staffschedules add constraint FK1hq0w0wc2sovom7mtjq48tfjd foreign key (user_id) references users;
alter table stockitems add constraint FK2vo0ak1cwun4kiwxfm9gkhxnk foreign key (raw_material_id) references rawmaterials;
alter table stockitems add constraint FKgemijcl3dmw29k2gxteao460g foreign key (store_id) references stores;
alter table stocktransactions add constraint FKf1qdauigw9v1hrccc9x1e0tpt foreign key (manager_id) references users;
alter table stocktransactions add constraint FK20vf5rgx0y95fc45d04cjvrdk foreign key (stock_item_id) references stockitems;
alter table systemconfigs add constraint FKp5n5nufxpi9v5gnw3k76ha46o foreign key (store_id) references stores;
alter table users add constraint FK7wra86jadsraitoewujbjj1pd foreign key (store_id) references stores;
