# **I. Record of Changes**

| Date | A\*M, D | In charge | Change Description |
| ----- | ----- | ----- | ----- |
| 2026-06-18 | A | Software Engineering Team | Initial creation of RDS v1.0 — Iteration A: Section I (Record of Changes), Section 1.1 (System Architecture), Section 1.2 (Package Diagram), Section 2 (Database Design — 21 tables). |
| 2026-06-18 | A | Software Engineering Team | Iteration B: Section 3.1 (System Access & Security), Section 3.2 (User Management), Section 3.3 (Menu & Category Management), Section 3.4 (Voucher Management). |
| 2026-06-18 | A | Software Engineering Team | Iteration B cont.: Section 3.5 (Customer & Membership), Section 3.6 (Inventory & Stock), Section 3.7 (POS Transaction), Section 3.8 (Order Management). |
| 2026-06-18 | A | Software Engineering Team | Iteration B cont.: Section 3.9 (Staff Management), Section 3.10 (Reports & Analytics), Section 3.11 (System Configuration & Branch Management). |
| 2026-06-18 | M | Software Engineering Team | Simplified Section 1.2 Package Diagram to follow the core MVC 6-package structure (bean, view, controller, filter, dao, util). |
| 2026-06-18 | M | Software Engineering Team | Rebuilt Section 2 (Database Design) ERD to display full column definitions (PK, FK, types) inside each entity, matching Visual Paradigm format. Restored all 21 SRS entities with exact columns from SRS §3.1.6. |
| 2026-06-18 | M | Software Engineering Team | Split Section 2 Database Design ERD into 2 diagrams (Core Sales & POS, Operations/Staffing/Audit) to prevent cluttering and improve readability. |
| 2026-06-18 | M | Software Engineering Team | Translated Section 2.1 & 2.2 titles/descriptions to English and unified font formatting (monospace inline code blocks) for database tables, columns, PK, FK, enums, data types, and roles. |
| 2026-06-18 | M | Software Engineering Team | Standardized Section 1.2 Package Diagram to UML package diagram conventions (Visual Paradigm style), organizing 18 subsystems into structured tiers with explicit dependency stereotypes (use, import, access). |
| 2026-06-18 | M | Software Engineering Team | Standardized all 4 Statechart diagrams (USER, VOUCHER, SHIFT, ORDER lifecycles) to UML-compliant syntax matching Visual Paradigm layout (Trigger [Guard] / Action format). |
| 2026-06-18 | M | Software Engineering Team | Standardized all 32 Sequence diagrams to UML method signature conventions, converting free-text labels to formal API/event operation calls. |
| 2026-06-27 | M | Software Engineering Team | Reconciliation pass: applied DOCS_RECONCILIATION A1–A59 fixes — UC-ID alignment, BR-ID corrections, variant/topping model, entity field additions across Sections 3.1–3.11. |
| 2026-06-27 | M | Software Engineering Team | Updated DB Design (Section 2) from 21 to 23 tables: added SystemConfig, MenuItemToppingMapping. Updated MenuItem variant fields, User lockout fields, Customer birthDate. |
| 2026-06-27 | M | Software Engineering Team | Rebuilt Section 1.2 Package Diagram to feature-based modular monolith (com.khoga). Updated stack: Spring Boot 4.1.0 / Java 21. |
| 2026-07-02 | M | Software Engineering Team | Fixed Section 1.2.2 Package Diagram: corrected web admin from React/Vite/TypeScript to Thymeleaf (Spring MVC server-side rendered). |\r\n| 2026-07-02 | M | Software Engineering Team | Moved Store Manager from Thymeleaf (web) to Flutter (mobile app) — shared app with Cashier \u0026 Barista (role-based routing). Renamed Flutter app from `khoga_pos_app` to `khoga_cafe_app`. Clarified 2 separate HQ admin roles (Business Admin + System Admin) sharing 1 web portal with CEO Viewer. |\r\n| 2026-07-02 | A | Software Engineering Team | Added Section 1.3 Deployment Diagram (UML notation) with execution environments, artifacts (display names), components, and communication paths. |

\*A – Added   M – Modified   D – Deleted
