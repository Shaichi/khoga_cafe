# 4. Non-Functional Requirements

This section describes system behaviors, attributes, constraints, and external interface properties that the Coffee Shop Management System must satisfy.

## 4.1 External Interfaces

This section provides information to ensure that the system will communicate properly with users and with external hardware or software/system elements.

### 4.1.1 User Interfaces
- **POS Terminal**: Touchscreen-optimized interface designed for high-speed cashier operations. Form layouts, buttons, and checkout workflows must fit fully on a single screen without vertical or horizontal scrolling.
- **Admin & Manager Portals**: Web-based responsive dashboards with clear menus, tables, and forms, supporting dark/light mode toggles and structured navigation grids.

### 4.1.2 Hardware Interfaces
- **POS Receipt Printer**: Connection via standard USB port or local network port using receipt print formatting.
- **Barista Label Sticker Printer**: Connection via USB or network port to print beverage and item sticker details.
- **POS Cash Drawer**: Placed in the cashier area, connected directly to the POS receipt printer via standard ports, popping open automatically upon cash transactions validation.

### 4.1.3 Software & API Interfaces
- **Payment Gateways**: API integration with bank systems (dynamic VietQR bank transfers) and payment services to receive instant payment confirmations.


---

## 4.2 Quality Attributes

This section details the required system characteristics and quality standards.

### 4.2.1 Usability

This section includes all requirements affecting usability, user productivity, task efficiency, and usability standards.

- **User Training & Productivity**:
  - **Normal Users (Cashiers, Baristas)**: A normal user must be able to operate basic features (e.g., login, select item, apply voucher, payment, or update preparation queue) productively after **less than 15 minutes** of training.
  - **Power Users (Store Managers, HQ Admins)**: A power user must be able to perform scheduling, inventory logs, and view sales metrics productively after **less than 1 hour** of training.
- **Measurable Task Times (Typical Tasks)**:
  - **POS checkout**: Cashier selects items, applies loyalty lookup, and opens payment options: **under 15 seconds** (typical task time).
  - **Menu lookup**: Filtering menu catalog items: **under 1 second**.
  - **Generate local reports**: Loading sales summaries on screen: **under 2 seconds**.
- **Usability Standards**:
  - All touchscreen interfaces must conform to standard touchscreen usability guidelines, with interactive buttons measuring at least **48x48 pixels** to prevent accidental clicks.
  - Form fields must feature inline validation messages and keyboard tabbing layouts in conformity with common desktop interface design standards.

### 4.2.2 Reliability

Requirements for system reliability, availability, fault tolerance, and bug rates.

- **Availability**:
  - **System Availability**: The cloud system and APIs must maintain at least **99.9% uptime**, **measured excluding the scheduled maintenance window** below (so planned maintenance does not consume the error budget). This reconciles the SLA with the maintenance allowance — the two no longer contradict (RV-C17).
  - **Maintenance Access**: System maintenance is scheduled during low-traffic periods (02:00 AM to 04:00 AM on Sundays), must not exceed **2 hours per month**, and is announced in advance; downtime inside this window is excluded from the 99.9% measurement.
  - **Degraded Mode Operations**: Not supported. The POS Terminal operates as an always-online application and requires active internet connectivity. If connection to the cloud backend or payment gateway is lost, transaction checkout is suspended until connectivity is restored.
- **System Stability & Crash-free Rate**:
  - The crash-free session rate for both POS client applications and server-side components must be at least **99.9%** (measured over any 30-day window).
- **Mean Time To Repair (MTTR)**:
  - In the event of a system failure, the MTTR for critical cloud services must be **under 2 hours**.
  - The MTTR for cashier hardware errors at a branch (e.g., POS printer failure) must be **under 15 minutes** using backup local devices.
- **Accuracy**:
  - All monetary and pricing calculations must be 100% accurate, rounded to the nearest integer for VND currency values.
  - Loyalty point accrual must calculate to exactly two decimal places before being rounded down to the nearest integer.
- **Defect Escape Rate**:
  - The defect escape rate (bugs found in production vs. total bugs found) must be **under 5%**, and there must be **zero critical or blocker defects** in any production release.
- **Defect Severity Categorization**:
  - **Minor**: Minor alignment issues, spelling typos, or cosmetic errors.
  - **Significant**: A functional feature has a workaround but doesn't block the core sales path (e.g., optional image thumbnail not displaying).
  - **Critical**: Defect causing complete data loss, security breach, or total inability to use core system features (e.g., POS checkout not responding, login page crashing). No critical bugs are permitted in production releases.

### 4.2.3 Performance

The system's performance characteristics, transaction response times, and capacity metrics.

- **Transaction Response Times**:
  - **UC-01 Login**: Average response time **under 1.0 second**, maximum response time **under 3.0 seconds**.
  - **UC-45 Add Item to Order**: Adding catalog items to POS checkout cart must respond in **under 100 milliseconds**.
  - **UC-51 Process Payment**: Processing cash checkout or starting QR code display must respond in **under 1.5 seconds**, with payment gateway callback validation in **under 5.0 seconds**.
  - **UC-28 View Consolidated Business Reports**: Central report compilation and display must load in **under 2.0 seconds** average, **under 5.0 seconds** maximum.
- **Throughput**:
  - The backend APIs must handle a minimum throughput of **100 transactions per second (TPS)** globally without degradation.
- **Capacity** *(expressed per-branch × `MAX_ACTIVE_BRANCHES`, not as fixed totals — RV-C16)*:
  - **Per branch**: at least **50 concurrent active POS/staff sessions** and **2,000 order transactions per day** (consistent with the §4.2.5 single-branch floor).
  - **Chain total**: scales as `per-branch capacity × MAX_ACTIVE_BRANCHES`. The architecture must scale with `MAX_ACTIVE_BRANCHES` without redesign — there is **no hardcoded chain-wide ceiling** (the former fixed "100 sessions / 10,000 orders" figures are removed).
- **Resource Utilization**:
  - **POS client memory**: The active application must consume **less than 512MB RAM** on terminal devices.
  - **Local storage disk footprint**: Local cached orders and master catalog data must require **less than 2GB of disk storage**.
  - **Network bandwidth**: API communications must be compressed, consuming **less than 10KB of payload data** per standard order transaction.

### 4.2.4 Security & Compliance
- **Data Encryption**: All network traffic must run over HTTPS using TLS 1.3 protocol. Passwords must be securely hashed before being saved.
- **Session Tokens & Silent Refresh**: 
  - Expiration limits of 8 hours for cashiers/baristas and 2 hours for administrators.
  - To prevent active cashiers from being logged out mid-shift, a background token refresh request executes every time the token has less than 30 minutes of remaining validity, provided there is active user interaction. If the user is idle for more than 30 minutes, they will be automatically logged out.
- **Access Control**: Strict role-based access control (RBAC) enforced on all resource endpoints. Unauthorised attempts to access administrative features will return access denied errors.

### 4.2.5 Scalability
- The system architecture must support horizontal scaling to accommodate a dynamic number of branches (configured via `MAX_ACTIVE_BRANCHES`) without requiring architectural redesign.
- A single branch deployment must handle at least **2,000 transactions per day** and **50 concurrent active users** without performance degradation; chain-wide capacity scales as this per-branch figure × `MAX_ACTIVE_BRANCHES` (per §4.2.3, RV-C16).

### 4.2.6 Data Retention & Archival
- **Transaction Records** (Orders, Payments): Retained for a minimum of **5 years** to comply with financial audit requirements.
- **Audit Logs**: Retained for a minimum of **2 years**.
- **Shift Sessions**: Retained for **1 year**, then archived to cold storage.
- **Customer PII** (phone, email, name): Retained for **24 months from the customer's last transaction**, then irreversibly anonymised; aggregate sales history is preserved without PII (BR-72).
- **Attendance camera snapshots** (`attendance_logs.photo_url`): Auto-deleted **90 days** after capture via the `photo_purge_at` job (BR-72); the attendance row (times, lateness inputs) is retained for payroll with `photo_url` nulled.
- Data older than retention limits may be archived to a read-only cold storage tier and will not appear in active reports.

#### 4.2.6.1 Personal Data Protection (PDPA / Decree 13/2023)
- **Consent**: Customer enrolment captures explicit consent (`consent_at`, `consent_version`) before any PII is stored (BR-71). Attendance biometrics-adjacent photos are collected solely for clock-in fraud prevention and are subject to the 90-day purge above.
- **Right to erasure**: The system must support a data-subject erasure/anonymisation request for a specific customer ahead of the 24-month window (BR-72). Erasure detaches PII from legally mandated financial records (5-year orders/payments) rather than deleting the transaction itself.
- **Lawful basis & minimisation**: Only the data fields specified in §3.8 (customer) and §3.9 (attendance) are collected; `ceoviewer` exports are restricted to aggregate, non-row-level PII (see RV-S12 backlog).

### 4.2.7 Backup & Disaster Recovery
- **Recovery Point Objective (RPO)**: Maximum data loss tolerance is **1 hour**. Automated database backups must run every 60 minutes.
- **Recovery Time Objective (RTO)**: System must be restorable and operational within **4 hours** of a declared disaster event.
- Backups must be stored in a geographically separate location from the primary server.

### 4.2.8 Browser & Device Support
- **Admin Dashboard**: Must support the latest two stable versions of Google Chrome, Mozilla Firefox, and Microsoft Edge on Windows/macOS desktop.
- **POS Terminal & Mobile Application**: Built using Flutter, supporting:
  - Android mobile and tablet devices (Android 9.0 / API 28 and above).
  - iOS mobile and tablet devices (iOS 14.0 and above).
  - Windows 10+ for desktop touchscreen terminals.
- **Minimum Screen Resolution**:
  - Mobile (Portrait): 720×1280px.
  - Tablet (Landscape): 1280×800px.
  - Desktop Terminal: 1366×768px.
