# 1. Product Overview

The Coffee Shop Management System is an integrated software solution designed to streamline the operations of a modern coffee shop. This section details the objectives, scope, and system context of the product.

## 1.1 Product Purpose & Objectives
The primary purpose of the Coffee Shop Management System is to automate, coordinate, and optimize daily coffee shop operations. The system aims to achieve the following key objectives:
- **Operational Efficiency**: Accelerate order taking, processing, and checkout workflows at the Point of Sale (POS).
- **Inventory Control**: Real-time tracking of ingredients, automated low-stock alerts, and structured audit procedures to minimize wastage and stockouts.
- **Role-based Access & Security**: Establish clear operational boundaries and authorization levels for HQ roles (executive viewer, business admin, system admin), store managers, cashiers, and baristas.
- **Data-Driven Insights**: Deliver comprehensive financial, inventory, and staff performance reports to enable management to make informed business decisions.

## 1.2 Product Scope
The system will manage the following core domains:
- **Authentication & Security**: Multi-role login, profile updates, and secure account creation/management.
- **Catalog & Promotion**: Dynamic category and menu creation, pricing adjustments, options/toppings management, and voucher configurations.
- **Inventory Audit & Logistics**: Standardized stock import (nhập kho), stock export (xuất kho), low-stock monitoring, and audit logs.
- **POS & Order Transactions**: Efficient shift management, barcode/text menu search, order line assembly, automatic discount calculations, tax/invoice generation, and order queues.
- **Human Resources**: Barista and cashier schedule creation, viewable shift schedules, and staff attendance reports.
- **Customer CRM**: Member point accumulation, lookup, and historical purchase data.
- **Reporting**: Monthly store revenue charts, consolidated business reports, and export options.

### Out of Scope
The system will *not* support:
- **Real-time Order Processing & Delivery Integration**: Direct handling of online order lifecycles, courier dispatching, or kitchen sync with third-party delivery apps.
- **Payroll Calculation & Payouts**: The system will track staff schedules and attendance reports, but financial payroll calculations and payroll payouts are handled by external accounting systems.

---

## 1.3 System Context Diagram
The system context diagram below illustrates the external entities interacting with the Coffee Shop Management System and the primary data flows between them.

```mermaid
graph LR
    linkStyle default interpolate linear

    SYS((COFFEE SHOP MANAGEMENT SYSTEM))
    CEOVIEWER[CEO / Executive Viewer]
    BIZADMIN[Business Admin - Ops & Marketing]
    SSADMIN[System Admin - IT]
    MANAGER[Store Manager]
    CASHIER[Cashier]
    BARISTA[Barista]

    style SYS fill:#fff,stroke:#000,stroke-width:2px
    style CEOVIEWER fill:#fff,stroke:#000,stroke-width:1px
    style BIZADMIN fill:#fff,stroke:#000,stroke-width:1px
    style SSADMIN fill:#fff,stroke:#000,stroke-width:1px
    style MANAGER fill:#fff,stroke:#000,stroke-width:1px
    style CASHIER fill:#fff,stroke:#000,stroke-width:1px
    style BARISTA fill:#fff,stroke:#000,stroke-width:1px

    %% 1a. CEO / Executive Viewer Data Flows (read-only)
    SYS --> |"Consolidated Business Reports"| CEOVIEWER
    SYS --> |"Authentication Status"| CEOVIEWER

    %% 1b. Business Admin Data Flows (Ops & Marketing)
    BIZADMIN --> |"Central Menu & Recipe Data"| SYS
    BIZADMIN --> |"Campaign & Promotion Data"| SYS
    BIZADMIN --> |"Customer / CRM Data"| SYS

    %% 1c. System Admin Data Flows (IT)
    SSADMIN --> |"User Management Data"| SYS
    SSADMIN --> |"System Configurations"| SYS
    SSADMIN --> |"Branch Lifecycle Data"| SYS

    %% 2. Store Manager Data Flows
    MANAGER --> |"Local Stock Import/Export Data"| SYS
    MANAGER --> |"Inventory Audit Data"| SYS
    MANAGER --> |"Staff Scheduling Data"| SYS
    SYS --> |"Store Revenue Report"| MANAGER
    SYS --> |"Low Stock Alerts"| MANAGER
    SYS --> |"Staff Attendance Report"| MANAGER

    %% 3. Cashier Data Flows
    CASHIER --> |"Order Data"| SYS
    CASHIER --> |"Payment Details"| SYS
    CASHIER --> |"Customer Membership ID"| SYS
    SYS --> |"Printed Invoice"| CASHIER
    SYS --> |"Transaction Status"| CASHIER
    SYS --> |"Membership Points Status"| CASHIER

    %% 4. Barista Data Flows
    BARISTA --> |"Order Status Update"| SYS
    SYS --> |"Drink Label Data (Sticker)"| BARISTA
    SYS --> |"Queue Display Data"| BARISTA
```
