### **3.11 System Configuration & Branch Management**

*\[Provide the detailed design for System Configuration & Branch Management, covering UC-30 (Central System Config by ssadmin), UC-42 (Branch Local Settings by storemanager), and UC-63→UC-65 (Branch Lifecycle: View List / Add / Update-Deactivate by ssadmin). Key constraints: Adding a branch is blocked if MAX_ACTIVE_BRANCHES is reached (BR-54). Deactivating a branch is blocked while the branch has OPEN shift sessions or any non-terminal order (BR-55), and on deactivation it cascades per BR-56. All config changes are audit-logged.\]*

#### ***3.11.1 Class Diagram***

*\[Class diagram for Config & Branch Management. COMET stereotypes: SystemConfigForm, BranchLocalSettingsForm, AddBranchForm, EditBranchForm, BranchListView («boundary»); SystemConfigCoordinator, BranchCoordinator («control»); SystemConfig, Store, AuditLog («entity»).\]*

```mermaid
classDiagram
    class SystemConfigForm {
        <<boundary>>
        +configKey: String
        +configValue: String
        +scope: ConfigScope
        +submitUpdate()
    }
    class BranchLocalSettingsForm {
        <<boundary>>
        +storeId: UUID
        +timezone: String
        +printerIpOrCom: String
        +cashDrawerIpOrCom: String
        +logo: Image
        +submitSettings()
    }
    note for BranchLocalSettingsForm "UC-42 / BR-47: a FIXED, TYPED settings form owned by the Store Manager (timezone, hardware IP/COM, branch logo) — NOT a generic config key/value override. ssadmin does NOT edit branch-local settings; ssadmin's branch authority is lifecycle UC-63 to UC-65 only."
    class AddBranchForm {
        <<boundary>>
        +name: String
        +address: String
        +phone: String
        +submitCreate()
    }
    class EditBranchForm {
        <<boundary>>
        +storeId: UUID
        +updateFields: StoreDto
        +submitChanges()
    }
    class BranchListView {
        <<boundary>>
        +displayBranches()
        +searchFilter: String
    }
    class SystemConfigCoordinator {
        <<control>>
        +getSystemConfig(key): ConfigDto
        +updateSystemConfig(key, value): void
        +getBranchLocalSettings(storeId): BranchSettingsDto
        +updateBranchLocalSettings(storeId, settings): void
    }
    class BranchCoordinator {
        <<control>>
        +listBranches(filter): List~StoreDto~
        +addBranch(dto): Store
        +updateBranch(id, dto): Store
        +deactivateBranch(id): void
    }
    class SystemConfig {
        <<entity>>
        +id: UUID
        +configKey: String
        +configValue: String
        +scope: ConfigScope
        +storeId: UUID
        +updatedBy: UUID
        +updatedAt: DateTime
    }
    class Store {
        <<entity>>
        +id: UUID
        +name: String
        +address: String
        +phone: String
        +isActive: Boolean
        +createdAt: DateTime
    }
    class AuditLog {
        <<entity>>
        +writeLog(actionType, entity, old, new)
    }

    SystemConfigForm ..> SystemConfigCoordinator
    BranchLocalSettingsForm ..> SystemConfigCoordinator
    AddBranchForm ..> BranchCoordinator
    EditBranchForm ..> BranchCoordinator
    BranchListView ..> BranchCoordinator
    SystemConfigCoordinator --> SystemConfig
    SystemConfigCoordinator --> AuditLog
    BranchCoordinator --> Store
    BranchCoordinator --> AuditLog
```

#### ***3.11.2 UC-30 Central System Configuration***

*\[ssadmin manages central system-wide configurations: tax rate, loyalty earn rate (points per VND), loyalty redemption rate (VND per point), VietQR API credentials, MAX_ACTIVE_BRANCHES, and other global parameters. Every change is audit-logged (BR-80). Config values are loaded fresh from DB on each request (no restart needed).\]*

```mermaid
sequenceDiagram
    actor ssadmin
    participant ConfigForm as SystemConfigForm
    participant ConfigCoord as SystemConfigCoordinator
    participant ConfigDB as SystemConfig (DB)
    participant AuditDB as AuditLog (DB)

    ssadmin->>ConfigForm: openConfigPanel()
    ConfigForm->>ConfigCoord: getSystemConfig(key="*")
    ConfigCoord->>ConfigDB: findAllGlobalConfigs()
    ConfigDB-->>ConfigCoord: configList[] (TAX_RATE, LOYALTY_EARN_RATE, LOYALTY_REDEEM_RATE,<br/>VIETQR_API_CLIENT_ID, VIETQR_API_API_KEY, VIETQR_API_CHECKSUM_KEY,<br/>MAX_ACTIVE_BRANCHES, CANCEL_REFUND_ALERT_THRESHOLD, ...)
    ConfigCoord-->>ConfigForm: displayConfigGrid()

    ssadmin->>ConfigForm: inputConfigValue(key, value)
    ConfigForm->>ConfigCoord: updateSystemConfig(key, newValue, scope=GLOBAL)
    ConfigCoord->>ConfigDB: findByKey(key)
    ConfigDB-->>ConfigCoord: oldConfig
    ConfigCoord->>ConfigDB: updateConfig(key, newValue, updatedBy=ssadmin.id, updatedAt=now)
    ConfigCoord->>AuditDB: writeAuditLog(CONFIG_UPDATE, system_configs, oldConfig, newConfig)
    ConfigCoord-->>ConfigForm: showSuccess(key, newValue)
    ConfigForm-->>ssadmin: displayUpdatedConfigGrid()
```

#### ***3.11.3 UC-63/64/65 Branch Lifecycle Management***

*\[ssadmin views the branch list (UC-63), adds a branch (UC-64), or updates/deactivates a branch (UC-65). Adding a branch checks the MAX_ACTIVE_BRANCHES constraint (BR-54). Deactivating a branch is blocked while the branch has any OPEN shift session OR any non-terminal order (status PENDING/PREPARING/HOLD/READY) per BR-55. On successful deactivation the change cascades per BR-56 (disable branch users + terminate their tokens, delete future schedules + notify, preserve historical records read-only). All operations are audit-logged.\]*

```mermaid
sequenceDiagram
    actor ssadmin
    participant BranchForm as AddBranchForm / EditBranchForm
    participant BranchCoord as BranchCoordinator
    participant ConfigDB as SystemConfig (DB)
    participant ShiftDB as ShiftSession (DB)
    participant OrderDB as Order (DB)
    participant StoreDB as Store (DB)
    participant UserDB as User (DB)
    participant SchedDB as Schedule (DB)
    participant AuditDB as AuditLog (DB)

    ssadmin->>BranchForm: submitBranchAction(dto)
    BranchForm->>BranchCoord: submitAction(dto)

    alt ADD Branch (UC-64)
        BranchCoord->>ConfigDB: getConfig(MAX_ACTIVE_BRANCHES)
        ConfigDB-->>BranchCoord: maxBranches = N
        BranchCoord->>StoreDB: countActiveBranches()
        StoreDB-->>BranchCoord: currentCount = C
        BranchCoord->>BranchCoord: validate(C < N) — blocked if C >= N (BR-54)
        BranchCoord->>StoreDB: createStore(dto, isActive=true)
        StoreDB-->>BranchCoord: newStore
        BranchCoord->>AuditDB: writeAuditLog(CREATE, stores, null, newStore)
    else UPDATE Branch (UC-65)
        BranchCoord->>StoreDB: findById(storeId)
        StoreDB-->>BranchCoord: oldStoreRecord
        BranchCoord->>StoreDB: updateStore(storeId, dto)
        BranchCoord->>AuditDB: writeAuditLog(UPDATE, stores, oldRecord, newRecord)
    else DEACTIVATE Branch (UC-65)
        BranchCoord->>ShiftDB: findOpenShifts(storeId)
        ShiftDB-->>BranchCoord: openShiftsList (must be empty)
        BranchCoord->>OrderDB: findNonTerminalOrders(storeId, status in [PENDING,PREPARING,HOLD,READY])
        OrderDB-->>BranchCoord: nonTerminalOrders (must be empty)
        BranchCoord->>BranchCoord: validate(openShifts.isEmpty() AND nonTerminalOrders.isEmpty()) — blocked otherwise (BR-55)
        BranchCoord->>StoreDB: setIsActive(storeId, false)
        Note over BranchCoord,SchedDB: Cascade on deactivation (BR-56)
        BranchCoord->>UserDB: disableBranchUsers(storeId) + terminateTokens (BR-18)
        BranchCoord->>SchedDB: deleteFutureSchedules(storeId) + notifyAffectedStaff (BR-37)
        Note over BranchCoord,StoreDB: historical records preserved read-only
        BranchCoord->>AuditDB: writeAuditLog(DEACTIVATE, stores, isActive=true, isActive=false)
    end

    BranchCoord-->>BranchForm: showSuccess()
    BranchForm-->>ssadmin: refreshBranchList()
```

