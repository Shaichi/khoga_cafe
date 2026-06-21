# 3.2 System Access & Security

This section details the functional requirements for authentication, user profiles, and employee account administration.

---

## 3.2.0 Role-Based Access Control (RBAC) Overview

The system defines six user roles with strictly separated permissions. The table below is the authoritative reference for all access decisions.

| Role Identifier | Display Name | Scope | Permitted Actions |
|---|---|---|---|
| `ceoviewer` | CEO / Executive Viewer | HQ | **Read-only** access to HQ Dashboard and all chain-wide reports. Cannot create, edit, or delete any data (menu items, vouchers, user accounts, etc.). |
| `businessadmin` | Ops & Marketing Admin | HQ | Full CRUD on chain-wide menu, recipe formulas, categories, vouchers, and CRM customer data. Cannot access system configuration or user account provisioning. |
| `ssadmin` | IT System Admin | HQ | System configuration (hardware, VietQR/OTP integration, license, `MAX_ACTIVE_BRANCHES`). Cannot access sales or CRM data. |
| `storemanager` | Store Manager | Branch | Inventory import/export/audit for own branch, staff schedule management, shift close approval, temporary item deactivation via `branch_menu_status`. |
| `cashier` | POS Cashier | Branch | POS checkout, open/close shift (own user session only), customer lookup, order history for own branch. |
| `barista` | Barista | Branch | Barista KDS queue view, START PREP, READY (one-touch), REPORT ISSUE, print cup stickers. |

### Permission Matrix Summary

| Feature | ceoviewer | businessadmin | ssadmin | storemanager | cashier | barista |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| HQ Dashboard / Chain Reports | Read | — | — | — | — | — |
| Menu & Recipe Management | — | CRUD | — | — | — | — |
| Voucher & CRM Management | — | CRUD | — | — | — | — |
| System Configuration | — | — | CRUD | — | — | — |
| User Account Provisioning | — | — | — | — | — | — |
| Branch Inventory | — | — | — | CRUD | — | — |
| Branch Menu Status (temp. disable) | — | — | — | Write | — | — |
| Staff Scheduling | — | — | — | CRUD | — | — |
| Shift Close Approval | — | — | — | Approve | — | — |
| POS Checkout / Shift Open | — | — | — | — | Write | — |
| Barista KDS / Cup Stickers | — | — | — | — | — | Write |

> **Note**: User account provisioning (create/edit employee accounts, assign roles) is restricted to `ssadmin` for HQ-level accounts and to `ssadmin` + `storemanager` (read-only view) for branch accounts. `businessadmin` does **not** have user management access.

---

## 3.2.1 F01 - Login / UC-01 Login

### 3.2.1.1 Screen Mock-up (Mobile Portrait)
```
+------------------------------------+
|               Login                |
|                                    |
|  [Logo Coffee Shop]                |
|                                    |
|  User Name                         |
|  [ Username                      ] |
|                                    |
|  Password                          |
|  [ **********                    ] |
|                                    |
|         [      LOGIN      ]        |
|                                    |
|         _Forgot Password?_         |
|                                    |
+------------------------------------+
```

#### Table 3-1: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | User Name | Text | Yes | 50 | Account login name. |
| 2 | Password | Password | Yes | 255 | Masked input field for password entry. |
| 3 | Login | Button | | | Triggers credential verification and logs the user in. |
| 4 | Forgot Password | Link | | | Navigates user to Forgot Password flow. |

### 3.2.1.2 Use Case Description

| Use Case ID | UC-01 | Use Case Name | Login |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | CEO Viewer, Business Admin, System Admin, Store Manager, Cashier, Barista |
| **Description** | Allows authorized staff members to authenticate and access their specific operational portals. |
| **Precondition** | User account is active and user is not currently logged in. |
| **Trigger** | User opens the application and lands on the Login screen. |
| **Post-Condition** | User is successfully authenticated, session is established, and user is redirected to their homepage. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | User | Enters Username and Password, and clicks the "Login" button. |
| 2 | Portal | Verifies the credentials and checks account status. |
| 2a | Portal | **If the account is an HQ role** (`ceoviewer` / `businessadmin` / `ssadmin`) and `HQ_MFA_REQUIRED` is on, challenges for a second factor before establishing the session (BR-83 — see AT4). |
| 3 | Portal | Validates successful login (and MFA if required) and redirects the user to the interface matching their role. |

#### Alternative Flows
##### AT1: Invalid Credentials
- **Trigger**: At step 2, the user enters incorrect username or password.

| Sub-step | Actor | Action |
|---|---|---|
| 2.1 | Portal | Displays warning message: `"Incorrect username or password. Remaining attempts: {count}."` (MSG02) |

##### AT2: Mandatory Password Reset
- **Trigger**: At step 3, the account is flagged for mandatory password change.

| Sub-step | Actor | Action |
|---|---|---|
| 3.1 | Portal | Redirects the user immediately to the Force Password Change screen and restricts access to other areas. |

##### AT3: Too Many Failed Login Attempts
- **Trigger**: At step 2, 5 consecutive failed login attempts occur.

| Sub-step | Actor | Action |
|---|---|---|
| 2.1 | Portal | Suspends the user account from login attempts for 15 minutes, unless manually unlocked by a Store Manager (for branch staff) or System Admin (for any user). |

##### AT4: HQ Multi-Factor Authentication (MFA)
- **Trigger**: At step 2a, password is valid for an HQ-role account (`ceoviewer` / `businessadmin` / `ssadmin`) and `HQ_MFA_REQUIRED` is on.

| Sub-step | Actor | Action |
|---|---|---|
| 2a.1 | Portal | Sends a 6-digit MFA code to the account's registered email (reusing the OTP channel) **or** prompts for the current TOTP authenticator code, and shows the MFA Challenge screen (screen 58). |
| 2a.2 | User | Enters the second-factor code and submits. |
| 2a.3 | Portal | On match, establishes the session (step 3). On 3 failed attempts, applies the same lockout as AT3 (BR-17 reuse) and does **not** establish the session. |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-10 | Accounts with `is_active = false` must be blocked from logging in. |
| BR-11 | Account suspension lasts exactly 15 minutes after 5 consecutive failed attempts. |
| BR-12 | Mandatory password change flag blocks navigation to any other module. |
| BR-83 | **Mandatory MFA for HQ Roles**: Login by an HQ role (`ceoviewer` / `businessadmin` / `ssadmin`) requires a **second factor** after the password — a 6-digit email OTP (reusing the UC-03/04 OTP infrastructure) or a TOTP authenticator code — governed by the parameter `HQ_MFA_REQUIRED` (default **true**). Branch/POS roles (`storemanager`, `cashier`, `barista`) are **exempt** to avoid interrupting shared-terminal shift operations (they rely on password + attendance PIN per BR-53). Three failed MFA attempts trigger the standard lockout (BR-17) and block the session. (RV-S05) |

---

## 3.2.2 F02 - Logout / UC-02 Logout

### 3.2.2.1 Screen Mock-up (Mobile Portrait Confirmation)
```
+------------------------------------+
|        Logout Confirmation         |
|                                    |
|                                    |
|   Are you sure you want to log     |
|   out of the application?          |
|                                    |
|                                    |
|      [ Cancel ]     [ Log Out ]    |
|                                    |
+------------------------------------+
```

#### Table 3-2: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Cancel | Button | | | Aborts logout flow and returns to current active page. |
| 2 | Log Out | Button | | | Clears active session, logs action, and returns to Login. |

### 3.2.2.2 Use Case Description

| Use Case ID | UC-02 | Use Case Name | Logout |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | CEO Viewer, Business Admin, System Admin, Store Manager, Cashier, Barista |
| **Description** | Safely terminates the active user session. |
| **Precondition** | User is authenticated. |
| **Trigger** | User clicks the "Logout" button/link. |
| **Post-Condition** | Active session tokens are cleared, logout is logged, and user is returned to Login screen. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | User | Clicks the Logout option. |
| 2 | Portal | Displays logout confirmation modal. |
| 3 | User | Clicks "Log Out" button. |
| 4 | Portal | Terminates active session, records timestamp, and redirects to Login screen. |

#### Alternative Flows
##### AT1: Logout With Active Shift Session
- **Trigger**: At step 2, Cashier has an active POS shift session open on the terminal.

| Sub-step | Actor | Action |
|---|---|---|
| 2.1 | Portal | Displays confirmation: `"Your personal session will be closed. The POS shift session on this terminal will remain open so another cashier can continue."` |
| 2.2 | Cashier | Confirms logout. Portal terminates the **User Session** token only. The **Shift Session** on the POS register remains active and unaffected. |

> **Design Note**: User Session and Shift Session are independent lifecycle objects. A cashier may log out of their personal account (e.g. short break, mid-shift role change) without triggering cash-drawer reconciliation. The shift remains open on the terminal register under its assigned POS register ID until explicitly closed via UC-53.

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-13 | Logout time must be logged upon termination of user session. |
| BR-60 | **User Session / Shift Session Independence**: Terminating a cashier's User Session does not close the active Shift Session on the POS terminal. The Shift Session persists until explicitly closed by a cashier (UC-53) and approved by the Store Manager. |

---

## 3.2.3 F03 - Change Password / UC-09 Change Password

### 3.2.3.1 Screen Mock-up (Mobile Portrait)
```
+------------------------------------+
|          Change Password           |
|                                    |
|  Current Password                  |
|  [ **********                    ] |
|                                    |
|  New Password                      |
|  [ **********                    ] |
|                                    |
|  Confirm New Password              |
|  [ **********                    ] |
|                                    |
|         [ SAVE CHANGES ]           |
|                                    |
+------------------------------------+
```

#### Table 3-3: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Current Password | Password | Yes | 255 | Current masked password. |
| 2 | New Password | Password | Yes | 255 | New password adhering to complexity requirements. |
| 3 | Confirm New Password | Password | Yes | 255 | Re-enter new password to verify match. |
| 4 | Save Changes | Button | | | Submits change request. |

### 3.2.3.2 Use Case Description

| Use Case ID | UC-09 | Use Case Name | Change Password |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | CEO Viewer, Business Admin, System Admin, Store Manager, Cashier, Barista |
| **Description** | Allows logged-in users to update their password. |
| **Precondition** | User is authenticated. |
| **Trigger** | User navigates to Change Password screen in settings. |
| **Post-Condition** | User's password is changed successfully. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | User | Inputs Current Password, New Password, and Confirm Password, then clicks "Save Changes". |
| 2 | Portal | Verifies that Current Password is correct and New Password matches Confirm Password. |
| 3 | Portal | Saves new password, displays success message, and terminates other active sessions. |

#### Alternative Flows
##### AT1: Current Password Incorrect
- **Trigger**: At step 2, Current Password does not match recorded password.

| Sub-step | Actor | Action |
|---|---|---|
| 2.1 | Portal | Displays error message: `"The current password entered is incorrect."` |

##### AT2: Password Complexity Failed
- **Trigger**: At step 2, New Password does not meet complexity guidelines.

| Sub-step | Actor | Action |
|---|---|---|
| 2.1 | Portal | Displays error message: `"Password must be at least 8 characters long and contain uppercase, lowercase, numeric, and special characters."` |

##### AT3: Password Mismatch
- **Trigger**: At step 2, New Password and Confirm Password do not match.

| Sub-step | Actor | Action |
|---|---|---|
| 2.1 | Portal | Displays error message: `"Confirm password does not match the new password."` |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-14 | New passwords must be at least 8 characters, containing at least one uppercase letter, one lowercase letter, one number, and one special character. |
| BR-15 | New passwords cannot match the current password. |

---

## 3.2.4 F04 - Forgot Password / UC-03 Forgot Password

### 3.2.4.1 Screen Mock-up (Mobile Portrait)
```
+------------------------------------+
|          Forgot Password           |
|                                    |
|  Enter your registered email to    |
|  receive a verification OTP code.  |
|                                    |
|  Email Address                     |
|  [ email@example.com             ] |
|                                    |
|         [   SEND OTP   ]           |
|                                    |
|         _Back to Login_            |
+------------------------------------+
```

#### Table 3-4: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Email Address | Text | Yes | 100 | Registered work email address. |
| 2 | Send OTP | Button | | | Triggers sending verification OTP code to email. |
| 3 | Back to Login | Link | | | Navigates user back to Login screen. |

### 3.2.4.2 Use Case Description

| Use Case ID | UC-03 | Use Case Name | Forgot Password |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | CEO Viewer, Business Admin, System Admin, Store Manager, Cashier, Barista |
| **Description** | Initiates password recovery when a user forgets their credentials. |
| **Precondition** | User is not logged in. |
| **Trigger** | User clicks the "Forgot Password" link on the Login screen. |
| **Post-Condition** | If email is valid, OTP code is emailed and user is sent to OTP verification view. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | User | Enters registered email address and clicks "Send OTP". |
| 2 | Portal | Checks if the email is associated with an active user account. |
| 3 | Portal | Generates a 6-digit OTP code (valid for 10 minutes), emails it to the user, and redirects user to OTP Verification screen. |

#### Alternative Flows
##### AT1: Non-existent Email
- **Trigger**: At step 2, email address is not found.

| Sub-step | Actor | Action |
|---|---|---|
| 2.1 | Portal | Displays standard confirmation message to prevent account harvesting: `"If this email is registered, you will receive a reset OTP shortly."` |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-16 | OTP validity duration is exactly 10 minutes. |

---

## 3.2.5 F05 - Verify OTP / UC-04 Verify OTP

### 3.2.5.1 Screen Mock-up (Mobile Portrait)
```
+------------------------------------+
|             Verify OTP             |
|                                    |
|  Enter the 6-digit verification    |
|  code sent to your email.          |
|                                    |
|  Verification Code                 |
|  [ _ _ _ _ _ _ ]                   |
|                                    |
|         [  VERIFY CODE  ]          |
|                                    |
|         _Resend Code (59s)_        |
+------------------------------------+
```

#### Table 3-5: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Verification Code | Text | Yes | 6 | 6-digit numeric recovery code. |
| 2 | Verify Code | Button | | | Submits OTP for validation. |
| 3 | Resend Code | Link | | | Resends OTP (disabled during 60-second cooldown). |

### 3.2.5.2 Use Case Description

| Use Case ID | UC-04 | Use Case Name | Verify OTP |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | CEO Viewer, Business Admin, System Admin, Store Manager, Cashier, Barista |
| **Description** | Validates the 6-digit verification code sent during password recovery. |
| **Precondition** | Forgot password request has been initiated. |
| **Trigger** | Redirected from Forgot Password view. |
| **Post-Condition** | Code is validated, and user is sent to Set New Password screen. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | User | Enters the 6-digit OTP code and clicks "Verify Code". |
| 2 | Portal | Validates OTP match and checks expiration timeline. |
| 3 | Portal | Flags session as verified and redirects to Set New Password screen. |

#### Alternative Flows
##### AT1: Code Mismatch or Expired
- **Trigger**: At step 2, code is incorrect or older than 10 minutes.

| Sub-step | Actor | Action |
|---|---|---|
| 2.1 | Portal | Displays warning message: `"Invalid or expired verification code. Please request a new one."` |

##### AT2: Limit Exceeded
- **Trigger**: At step 2, 3 failed OTP submissions occur.

| Sub-step | Actor | Action |
|---|---|---|
| 2.1 | Portal | Disables recovery session, displaying message to restart forgot password flow. |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-17 | Maximum of 3 OTP attempts before recovery session is locked. |

---

## 3.2.6 F06 - Set New Password / UC-05 Set New Password

### 3.2.6.1 Screen Mock-up (Mobile Portrait)
```
+------------------------------------+
|          Set New Password          |
|                                    |
|  Create a new password for your    |
|  account.                          |
|                                    |
|  New Password                      |
|  [ **********                    ] |
|                                    |
|  Confirm Password                  |
|  [ **********                    ] |
|                                    |
|         [ RESET PASSWORD ]         |
|                                    |
+------------------------------------+
```

#### Table 3-6: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | New Password | Password | Yes | 255 | New password adhering to complexity requirements. |
| 2 | Confirm Password | Password | Yes | 255 | Re-enter new password to verify match. |
| 3 | Reset Password | Button | | | Submits password update. |

### 3.2.6.2 Use Case Description

| Use Case ID | UC-05 | Use Case Name | Set New Password |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | CEO Viewer, Business Admin, System Admin, Store Manager, Cashier, Barista |
| **Description** | Finalizes password recovery flow by configuring a new password. |
| **Precondition** | User session has a validated recovery status. |
| **Trigger** | Redirected from OTP Verification page. |
| **Post-Condition** | Password is updated and user redirected to Login. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | User | Enters new password, confirms it, and clicks "Reset Password". |
| 2 | Portal | Validates password complexity and match. |
| 3 | Portal | Updates account password, sets `must_change_password = false`, closes all active sessions elsewhere, and displays: `"Password reset successful. Please login with your new credentials."` |

#### Alternative Flows
##### AT1: Validation Failure
- **Trigger**: At step 2, inputs fail complexity or mismatch check.

| Sub-step | Actor | Action |
|---|---|---|
| 2.1 | Portal | Displays appropriate error message (same as Change Password errors). |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-14 | New passwords must be at least 8 characters, containing at least one uppercase letter, one lowercase letter, one number, and one special character. |
| BR-18 | Password change or setting status to Inactive terminates active session tokens on all other devices immediately. |

---

## 3.2.7 F06.1 - Force Password Change / UC-06 Force Password Change

### 3.2.7.1 Screen Mock-up (Mobile Portrait)
```
+------------------------------------+
|       Force Password Change        |
|                                    |
|  For security, you must change your|
|  temporary password before using   |
|  the system.                       |
|                                    |
|  New Password                      |
|  [ **********                    ] |
|                                    |
|  Confirm New Password              |
|  [ **********                    ] |
|                                    |
|         [ CHANGE PASSWORD ]        |
|                                    |
+------------------------------------+
```

#### Table 3-7: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | New Password | Password | Yes | 255 | Password input adhering to security requirements. |
| 2 | Confirm New Password | Password | Yes | 255 | Password input confirming the new password. |
| 3 | Change Password | Button | | | Submits the new password. |

### 3.2.7.2 Use Case Description

| Use Case ID | UC-06 | Use Case Name | Force Password Change |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | User (Base Staff) |
| **Description** | Forces a first-time logged-in user to replace their temporary password before accessing the system. |
| **Precondition** | User has logged in successfully using a temporary password. |
| **Trigger** | Portal detects that the user is logging in for the first time or has a flag to force password change. |
| **Post-Condition** | User's temporary password is replaced and user is redirected to the home screen. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | Portal | Displays the Force Password Change screen. |
| 2 | User | Enters a new secure password and confirms it. |
| 3 | User | Clicks "Change Password". |
| 4 | Portal | Validates that the password conforms to security standards and both entries match. |
| 5 | Portal | Updates the password, clears the force change flag, and redirects the user to their portal home. |

#### Alternative Flows
##### AT1: Validation Errors
- **Trigger**: Passwords do not match or fail security strength check.

| Sub-step | Actor | Action |
|---|---|---|
| 4.1 | Portal | Displays warning message: `"Passwords do not match."` or `"Password must be at least 8 characters long and include numbers."` |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-12 | Mandatory password change flag blocks navigation to any other module. User cannot bypass the Force Password Change screen. |

---

## 3.2.8 F07 - View Profile / UC-07 View Profile

### 3.2.8.1 Screen Mock-up (Mobile Portrait)
```
+------------------------------------+
|            My Profile              |
|                                    |
|  ID: EMP-042                       |
|  Name: Nguyen Van A                |
|  Username: nva_cashier             |
|  Role: Cashier                     |
|  Email: nva@coffeezone.com         |
|  Phone: 0987654321                 |
|  Store: Coffee Zone - Branch 1     |
|  Date Joined: 2026-01-15           |
|                                    |
|         [ EDIT PROFILE ]           |
|                                    |
+------------------------------------+
```

#### Table 3-8: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Edit Profile | Button | | | Navigates to Edit Profile screen. |

### 3.2.8.2 Use Case Description

| Use Case ID | UC-07 | Use Case Name | View Profile |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | CEO Viewer, Business Admin, System Admin, Store Manager, Cashier, Barista |
| **Description** | Allows logged-in staff to view their personal detail cards. |
| **Precondition** | User is authenticated. |
| **Trigger** | User selects the "Profile" option in settings/menu. |
| **Post-Condition** | Employee profile cards are displayed. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | User | Navigates to Profile view. |
| 2 | Portal | Retrieves employee ID, name, role, store, contact detail, and displays them. |

---

## 3.2.9 F08 - Update Profile / UC-08 Update Profile

### 3.2.9.1 Screen Mock-up (Mobile Portrait)
```
+------------------------------------+
|           Edit Profile             |
|                                    |
|  Contact Email                     |
|  [ nva@coffeezone.com            ] |
|                                    |
|  Contact Phone                     |
|  [ 0987654321                    ] |
|                                    |
|         [  SAVE PROFILE  ]         |
|                                    |
|         [     CANCEL     ]         |
+------------------------------------+
```

#### Table 3-9: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Contact Email | Text | Yes | 100 | Active contact email. |
| 2 | Contact Phone | Text | Yes | 20 | Phone number format (10-11 digits). |
| 3 | Save Profile | Button | | | Saves modifications and updates profile. |
| 4 | Cancel | Button | | | Discards edits and returns to View Profile screen. |

### 3.2.9.2 Use Case Description

| Use Case ID | UC-08 | Use Case Name | Update Profile |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | CEO Viewer, Business Admin, System Admin, Store Manager, Cashier, Barista |
| **Description** | Allows staff to modify their personal contact details. |
| **Precondition** | User is authenticated. |
| **Trigger** | User clicks the "Edit Profile" button. |
| **Post-Condition** | Profile info is modified. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | User | Edits Email or Phone, and clicks "Save Profile". |
| 2 | Portal | Validates inputs (conformance to email/phone format patterns, and checks uniqueness in the database; email and phone must not be registered to another active user account). |
| 3 | Portal | Updates account details and returns to View Profile screen. |

#### Alternative Flows
##### AT1: Validation Errors
- **Trigger**: At step 2, email or phone is invalid.

| Sub-step | Actor | Action |
|---|---|---|
| 2.1 | Portal | Displays error message: `"Please enter a valid email and phone number."` |

##### AT2: Duplicate Fields
- **Trigger**: At step 2, the entered email or phone number is already registered to another user account in the system.

| Sub-step | Actor | Action |
|---|---|---|
| 2.1 | Portal | Displays error message: `"This email address or phone number is already in use by another account."` |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-19 | Cashiers and Baristas can only change their own contact email and phone. The System Admin (`ssadmin`) updates administrative parameters (e.g. roles, branch assignment) via the account management tools; no other role can change roles. |

---

## 3.2.10 F09 - List User Account / UC-10 View User Account List

### 3.2.10.1 Screen Mock-up (Desktop Landscape)
```
+---------------------------------------------------------------------------------+
| HQ Portal > Employee Account Management                                      |
+---------------------------------------------------------------------------------+
|  Search: [ nva_cashier          ]   Role: [ All Roles ] [v]   Status: [Active]v |
|                                                                                 |
|  +-----+------------+---------------+---------+--------------------+---------+  |
|  | ID  | Username   | Full Name     | Role    | Email              | Status  |  |
|  +-----+------------+---------------+---------+--------------------+---------+  |
|  | 001 | nva_cashier| Nguyen Van A  | Cashier | nva@coffeezone.com | Active  |  |
|  | 002 | ssadmin_hq | Tran Thi B    | System Admin | admin@coffee.com | Active |  |
|  +-----+------------+---------------+---------+--------------------+---------+  |
|  [Page 1 of 5]                                              [ + Add Account ]  |
+---------------------------------------------------------------------------------+
```

#### Table 3-10: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Search | Text | No | 100 | Search criteria (Name, Username, Role). |
| 2 | Role | Dropdown | No | | Filters grid by employee role. |
| 3 | Status | Dropdown | No | | Filters grid by status (`Active` / `Inactive`). |
| 4 | Add Account | Button | | | Navigates to Add User Account view. |

### 3.2.10.2 Use Case Description

| Use Case ID | UC-10 | Use Case Name | View User Account List |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | System Admin |
| **Description** | Provides an administrative directory of all system accounts. |
| **Precondition** | System Admin is logged in. |
| **Trigger** | System Admin opens the Employee Account Management menu. |
| **Post-Condition** | Active grid of employee accounts is displayed. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | System Admin | Accesses Employee Account Management panel. |
| 2 | Portal | Displays filters and user listing grid (defaults to active accounts). |
| 3 | System Admin | Enters query or filter selection to search profiles. |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-20 | User accounts list supports pagination (default: 20 records per page). |

---

## 3.2.11 F10 - View User Details & History / UC-13 View User Account Detail

### 3.2.11.1 Screen Mock-up (Desktop Landscape)
```
+---------------------------------------------------------------------------------+
| HQ Portal > Employee Account Management > View Account Details               |
+---------------------------------------------------------------------------------+
|  ID: EMP-001          Full Name: Nguyen Van A          Role: Cashier            |
|  Username: nva        Email: nva@coffeezone.com        Phone: 0987654321        |
|  Status: Active       Joined: 2026-01-15               Branch: Store 1          |
|                                                                                 |
|  Activity History Log (Last 5 logins / actions):                                |
|  - 2026-05-24 08:00:15 - Successful Login                                       |
|  - 2026-05-23 22:01:00 - Closed Shift (Session ID: #104)                        |
|                                                                                 |
|                                                  [ Edit User ]    [ Back ]      |
+---------------------------------------------------------------------------------+
```

#### Table 3-11: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Edit User | Button | | | Navigates to Update User Account view. |
| 2 | Back | Button | | | Returns to Employee Account List. |

### 3.2.11.2 Use Case Description

| Use Case ID | UC-13 | Use Case Name | View User Account Detail |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | System Admin |
| **Description** | Displays full account profile details and operational history of a selected user. |
| **Precondition** | System Admin is logged in. |
| **Trigger** | System Admin selects a user account from the grid. |
| **Post-Condition** | Selected user's profile card and action history are displayed. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | System Admin | Selects an employee row. |
| 2 | Portal | Displays detailed profile information and activity history log. |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-21 | Activity history displays the last 50 logins, shift history, and changes made by the user. |

---

## 3.2.12 F11 - Add User Account / UC-11 Add User Account

### 3.2.12.1 Screen Mock-up (Desktop Landscape)
```
+---------------------------------------------------------------------------------+
| HQ Portal > Employee Account Management > Add Account                        |
+---------------------------------------------------------------------------------+
|  Username: [ nva_cashier      ]   Full Name:   [ Nguyen Van A             ]     |
|  Email:    [ nva@coffee.com   ]   Phone:       [ 0987654321               ]     |
|  Role:     [ Cashier      ] [v]   Branch Store:[ Branch 1             ] [v]     |
|                                                                                 |
|                                                [ Save Account ]    [ Cancel ]   |
+---------------------------------------------------------------------------------+
```

#### Table 3-12: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Username | Text | Yes | 50 | Account login name (unique). |
| 2 | Full Name | Text | Yes | 100 | Employee's full name. |
| 3 | Email | Text | Yes | 100 | Contact work email address (unique). |
| 4 | Phone | Text | Yes | 20 | Contact phone number. |
| 5 | Role | Dropdown | Yes | | Selects role: `ceoviewer` (CEO / Executive Viewer), `businessadmin` (Ops & Marketing), `ssadmin` (IT System Admin), `storemanager` (Store Manager), `cashier` (POS Cashier), `barista`. |
| 6 | Branch Store | Dropdown | Conditional | | Scopes storemanager / cashier / barista to a branch. **Leave blank (NULL) for HQ roles** (`ceoviewer`, `businessadmin`, `ssadmin`). |
| 7 | (None) | | | | Temporary password is auto-generated by the system (not entered by the System Admin). |
| 8 | Save Account | Button | | | Submits details to create account. |
| 9 | Cancel | Button | | | Discards details and returns to Employee list. |

### 3.2.12.2 Use Case Description

| Use Case ID | UC-11 | Use Case Name | Add User Account |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | System Admin |
| **Description** | Provisions a new employee account. |
| **Precondition** | System Admin is logged in. |
| **Trigger** | System Admin clicks "+ Add Account" on user list view. |
| **Post-Condition** | New user account created and login activation email is sent. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | System Admin | Fills out employee fields, assigns role and branch, and clicks "Save Account". |
| 2 | Portal | Validates constraints (username uniqueness, email uniqueness, phone uniqueness, and syntax format). |
| 3 | Portal | Registers account as active, auto-generates a secure random temporary password, sets the `must_change_password` flag to true, sends an activation welcome email with these credentials to the user, **writes a create-account entry to the immutable `AUDIT_LOG` (actor `ssadmin_id`, target user, assigned role, timestamp — BR-81)**, and returns to list view. |

#### Alternative Flows
##### AT1: Validation Errors
- **Trigger**: At step 2, checks fail.

| Sub-step | Actor | Action |
|---|---|---|
| 2.1 | Portal | Displays error message: `"Username or email already exists, or password complexity criteria not met."` |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-22 | Created accounts default status to active, and force a password change on next login. |
| BR-81 | **User Account Change Audit & Access Review**: Every account **create** (UC-11), **role / status change or deactivation** (UC-12/14), and **PIN/credential reset** writes an immutable `AUDIT_LOG` entry (actor `ssadmin_id`, target user, before/after role + status, timestamp). Because `ssadmin` (IT) can provision business-role accounts without a second approver (no maker-checker, consistent with BR-68), this audit trail plus the periodic **Access Review report** (UC-83, surfaced read-only to `ceoviewer`) is the compensating Segregation-of-Duties control. (RV-S03) |
| BR-82 | **Privilege Bootstrap & Self-Escalation Prevention**: (a) The **first** `ssadmin` account is provisioned via a secure one-time installation/seed process — never through the in-app user-management UI (resolves the chicken-and-egg bootstrap). (b) **No user may change their own role, permissions, or active status**; any role/status change to an account (especially HQ roles) must be performed by a *different* `ssadmin`. (c) All such changes are audit-logged per BR-81. Extends the last-admin protection (BR-23). (RV-S04) |
| BR-57 | **Employee ID Auto-Allocation**: When creating a new employee, the system must automatically allocate a unique sequential Employee ID with the format `EMP-{Sequence}` (e.g. `EMP-043` for the 43rd employee record). |
| BR-58 | **Real-time Username Generation**: The system must automatically generate a proposed username when the System Admin enters the employee's full name. The generation algorithm uses the formula: `[Normalized Main Name in Lowercase][Initials of Middle & Family Names][Clean Sequence ID]`. Vietnamese characters must be converted to plain English alphabet. The first letter of the main name must be lowercase (e.g. "Nguyễn Văn An" with sequence ID 43 -> "anNV43"). |


---

## 3.2.13 F12 - Update User Account / UC-12 Update User Account

### 3.2.13.1 Screen Mock-up (Desktop Landscape)
```
+---------------------------------------------------------------------------------+
| HQ Portal > Employee Account Management > Edit Account                       |
+---------------------------------------------------------------------------------+
|  Username: nva_cashier (Read-only)  Full Name:   [ Nguyen Van A             ]   |
|  Email:    [ nva@coffee.com   ]     Phone:       [ 0987654321               ]   |
|  Role:     [ Cashier      ] [v]     Branch Store:[ Branch 1             ] [v]   |
|  Status:   [ Active       ] [v]                                                 |
|                                                                                 |
|                                                [ Save Changes ]    [ Cancel ]   |
+---------------------------------------------------------------------------------+
```

#### Table 3-13: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Username | Label | | | Account username (cannot be modified). |
| 2 | Full Name | Text | Yes | 100 | Employee's name. |
| 3 | Email | Text | Yes | 100 | Contact email. |
| 4 | Phone | Text | Yes | 20 | Contact phone. |
| 5 | Role | Dropdown | Yes | | Account role. |
| 6 | Branch Store | Dropdown | No | | Store assignment. |
| 7 | Status | Dropdown | Yes | | Status selection (`Active` / `Inactive`). |
| 8 | Save Changes | Button | | | Submits updates. |
| 9 | Cancel | Button | | | Discards updates and returns to details. |

### 3.2.13.2 Use Case Description

| Use Case ID | UC-12, UC-14 | Use Case Name | Update & Deactivate User Account |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | System Admin |
| **Description** | Modifies employee account details or deactivates them to revoke access. |
| **Precondition** | System Admin is logged in. |
| **Trigger** | System Admin clicks "Edit User" on details page. |
| **Post-Condition** | Account parameters are updated and active tokens invalidated if deactivated. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | System Admin | Modifies employee parameters (name, contact, role) or sets status to Inactive (deactivating account), and clicks "Save Changes". |
| 2 | Portal | Validates inputs and flags. |
| 3 | Portal | Saves changes to USER registry, **writes a change entry to the immutable `AUDIT_LOG` (actor, target, before/after role + status, timestamp — BR-81)**. If deactivated, terminates active session tokens on all devices immediately (BR-18). |

#### Alternative Flows
##### AT1: Attempting to Deactivate Last System Admin
- **Trigger**: At step 2, the System Admin attempts to set the status of the last active `ssadmin` account to `Inactive` or to change its role.

| Sub-step | Actor | Action |
|---|---|---|
| 2.1 | Portal | Displays error message: `"Cannot deactivate the last remaining System Admin account."` |

##### AT3: Self-Escalation Blocked
- **Trigger**: At step 2, the System Admin attempts to change **their own** role, permissions, or active status.

| Sub-step | Actor | Action |
|---|---|---|
| 2.1 | Portal | Blocks the change and displays: `"You cannot change your own role or status. Another System Admin must perform this action."` (BR-82) |

##### AT2: Unlock Suspended User
- **Trigger**: System Admin (via Edit User) or Store Manager (via Branch Staff Details) views a user account currently suspended due to 5 failed login attempts.

| Sub-step | Actor | Action |
|---|---|---|
| 1 | Actor | Clicks "Unlock Account" button on the employee details screen. |
| 2 | Portal | Resets the failed login attempts counter to 0 and immediately unlocks the account. |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-23 | System must block any attempt to deactivate or change the role of the last active System Admin (`ssadmin`) account. |
| BR-18 | Password change or setting status to Inactive terminates active session tokens on all other devices immediately. |

---

## 3.2.14 F12.1 - HQ Multi-Factor Authentication Challenge / (part of UC-01)

### 3.2.14.1 Screen Mock-up (Desktop / Mobile)
```
+------------------------------------+
|        Verify It's You (MFA)       |
|                                    |
|  HQ account: biz_an                |
|  A 6-digit code was sent to your   |
|  registered email. Enter it below: |
|                                    |
|  Code: [ _ _ _ _ _ _ ]             |
|                                    |
|        [   VERIFY   ]              |
|   _Resend code (60s cooldown)_     |
+------------------------------------+
```

#### Table 3-70: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | HQ account | Label | | | The HQ-role username being authenticated. |
| 2 | Code | Text | Yes | 6 | Second-factor code: email OTP (UC-03/04 channel) or TOTP authenticator code. |
| 3 | Verify | Button | | | Submits the second factor; on match the session is established (UC-01 step 3). |
| 4 | Resend code | Link | | | Resends the email OTP (60-second cooldown); hidden for TOTP. |

> This screen appears only for HQ roles (`ceoviewer` / `businessadmin` / `ssadmin`) when `HQ_MFA_REQUIRED` is on (BR-83). It is part of the UC-01 login flow (AT4), not a standalone use case. Three failed attempts trigger the BR-17 lockout.

---

## 3.2.15 F12.2 - User Account Change & Access Review Report / UC-83 View Access Review Report

### 3.2.15.1 Screen Mock-up (Desktop Landscape)
```
+---------------------------------------------------------------------------------+
| Báo cáo › Rà soát tài khoản & truy cập                                          |
| Thay Đổi Tài Khoản & Rà Soát Truy Cập                                           |
+---------------------------------------------------------------------------------+
|  Từ ngày: [ 2026-05-01 ]     Đến ngày: [ 2026-05-31 ]     Vai trò: [ Tất cả v ] |
|                                                                                 |
|  +-----------------------------+ +-----------------------------+                |
|  | Tài khoản HQ đang hoạt động | | Thay đổi trong kỳ           |                |
|  | 7                           | | 12                          |                |
|  +-----------------------------+ +-----------------------------+                |
|  +-----------------------------+ +-----------------------------+                |
|  | Cấp lại mật khẩu            | | Tài khoản bị vô hiệu        |                |
|  | 3                           | | 1                           |                |
|  +-----------------------------+ +-----------------------------+                |
|                                                                                 |
|  Nhật ký thay đổi tài khoản (AUDIT_LOG — BR-81)                                 |
|  +------------------+------------------+-------------------+------------------+-----------------------------+  |
|  | Thời điểm        | Người thực hiện  | Hành động         | Tài khoản đích   | Chi tiết                    |  |
|  +------------------+------------------+-------------------+------------------+-----------------------------+  |
|  | 2026-05-15 10:22 | ss_admin         | Tạo tài khoản     | biz_minh         | Vai trò: businessadmin      |  |
|  | 2026-05-14 09:05 | ss_admin         | Đổi vai trò       | ops_lan          | ceoviewer -> businessadmin  |  |
|  | 2026-05-11 16:40 | ss_admin         | Cấp lại mật khẩu  | biz_an           | Bắt buộc đổi khi đăng nhập  |  |
|  | 2026-05-09 08:13 | ss_admin         | Vô hiệu hóa       | cashier_07       | Lý do: nghỉ việc            |  |
|  +------------------+------------------+-------------------+------------------+-----------------------------+  |
|                                                                                 |
|  Phục vụ rà soát định kỳ (attestation) tách biệt nhiệm vụ (SoD) — chỉ đọc (BR-81) |
+---------------------------------------------------------------------------------+
```

#### Table 3-71: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Từ ngày | Date Picker | Yes | | Reporting window start date for account changes. |
| 2 | Đến ngày | Date Picker | Yes | | Reporting window end date for account changes. |
| 3 | Vai trò | Dropdown | No | | Filter by role, or `Tất cả` (All). |
| 4 | Tài khoản HQ đang hoạt động | Card Stat | | | Displays active `ceoviewer` / `businessadmin` / `ssadmin` accounts for periodic attestation. |
| 5 | Thay đổi trong kỳ | Card Stat | | | Displays total account change log entries in the period. |
| 6 | Cấp lại mật khẩu | Card Stat | | | Displays total credential/password resets in the period. |
| 7 | Tài khoản bị vô hiệu | Card Stat | | | Displays total deactivated account log entries in the period. |
| 8 | Nhật ký thay đổi tài khoản grid | Grid | | | Read-only grid displaying `AUDIT_LOG` entries for create / role-change / status-change / deactivate / credential-reset (BR-81). Contains: Thời điểm, Người thực hiện, Hành động, Tài khoản đích, Chi tiết. |

### 3.2.15.2 Use Case Description

| Use Case ID | UC-83 | Use Case Name | View User Account Change & Access Review Report |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-06-14 | | |

| Field | Description |
|---|---|
| **Actor** | CEO Viewer (read-only) |
| **Description** | A read-only Segregation-of-Duties control: lists current HQ-role accounts for **periodic attestation** and every account create / role-change / deactivation / credential-reset from `AUDIT_LOG` (BR-81). Because `ssadmin` (IT) can provision business-role accounts unilaterally, this report lets the CEO detect inappropriate provisioning or privilege drift. |
| **Precondition** | CEO Viewer is logged in. |
| **Trigger** | CEO Viewer opens the Access Review report (e.g. quarterly attestation). |
| **Post-Condition** | Current HQ accounts and the account-change log are displayed; exportable via UC-29. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | CEO Viewer | Selects "Từ ngày", "Đến ngày", and optional "Vai trò" filter. |
| 2 | Portal | Retrieves active HQ accounts, period changes, password resets, deactivated accounts, and matching `AUDIT_LOG` account-change entries. |
| 3 | Portal | Displays the statistic cards and the "Nhật ký thay đổi tài khoản" grid. |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-81 | **User Account Change Audit & Access Review** (defined in §3.2.12): account create/role-change/deactivate/credential-reset are immutably logged; this report is the read-only attestation surface for `ceoviewer`. |


