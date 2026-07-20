-- Align SQL Server VARCHAR columns with JPA fields declared as NVARCHAR.
-- V1 created these columns as VARCHAR, but Hibernate reads them via getNString().
-- This caused: "The conversion from varchar to NCHAR is unsupported."

SET NOCOUNT ON;
SET XACT_ABORT ON;

-- auditlogs.entity_affected is used by an index, so drop and recreate the index.
IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = N'idx_audit_entity_created'
      AND object_id = OBJECT_ID(N'dbo.auditlogs')
)
BEGIN
    DROP INDEX idx_audit_entity_created ON dbo.auditlogs;
END;

ALTER TABLE dbo.attendancelogs ALTER COLUMN photo_url NVARCHAR(255) NULL;

ALTER TABLE dbo.auditlogs ALTER COLUMN entity_affected NVARCHAR(255) NULL;
ALTER TABLE dbo.auditlogs ALTER COLUMN old_value_json NVARCHAR(255) NULL;
ALTER TABLE dbo.auditlogs ALTER COLUMN new_value_json NVARCHAR(255) NULL;

CREATE INDEX idx_audit_entity_created
    ON dbo.auditlogs (entity_affected, created_at);

ALTER TABLE dbo.categorys ALTER COLUMN name NVARCHAR(255) NULL;
ALTER TABLE dbo.categorys ALTER COLUMN description NVARCHAR(255) NULL;

ALTER TABLE dbo.customers ALTER COLUMN phone NVARCHAR(255) NULL;
ALTER TABLE dbo.customers ALTER COLUMN full_name NVARCHAR(255) NULL;
ALTER TABLE dbo.customers ALTER COLUMN email NVARCHAR(255) NULL;
ALTER TABLE dbo.customers ALTER COLUMN consent_version NVARCHAR(255) NULL;

ALTER TABLE dbo.menuitems ALTER COLUMN name NVARCHAR(255) NULL;
ALTER TABLE dbo.menuitems ALTER COLUMN description NVARCHAR(255) NULL;
ALTER TABLE dbo.menuitems ALTER COLUMN image_url NVARCHAR(255) NULL;
ALTER TABLE dbo.menuitems ALTER COLUMN barcode NVARCHAR(255) NULL;
ALTER TABLE dbo.menuitems ALTER COLUMN abbreviation NVARCHAR(255) NULL;
ALTER TABLE dbo.menuitems ALTER COLUMN sku NVARCHAR(255) NULL;
ALTER TABLE dbo.menuitems ALTER COLUMN size_name NVARCHAR(255) NULL;

ALTER TABLE dbo.optiontoppings ALTER COLUMN name NVARCHAR(255) NULL;

ALTER TABLE dbo.ordercancellations ALTER COLUMN reason NVARCHAR(255) NULL;
ALTER TABLE dbo.ordercancellations ALTER COLUMN notes NVARCHAR(255) NULL;

ALTER TABLE dbo.orderrefunds ALTER COLUMN reason NVARCHAR(255) NULL;
ALTER TABLE dbo.orderrefunds ALTER COLUMN notes NVARCHAR(255) NULL;

ALTER TABLE dbo.orders ALTER COLUMN order_number NVARCHAR(255) NULL;
ALTER TABLE dbo.orders ALTER COLUMN transaction_ref NVARCHAR(255) NULL;

-- otp_tokens.id is the primary key, so drop/recreate the PK around its type change.
DECLARE @otpPkName SYSNAME;
DECLARE @dropOtpPkSql NVARCHAR(MAX);

SELECT @otpPkName = kc.name
FROM sys.key_constraints AS kc
WHERE kc.parent_object_id = OBJECT_ID(N'dbo.otp_tokens')
  AND kc.[type] = N'PK';

IF @otpPkName IS NOT NULL
BEGIN
    SET @dropOtpPkSql =
        N'ALTER TABLE dbo.otp_tokens DROP CONSTRAINT ' + QUOTENAME(@otpPkName) + N';';
    EXEC sys.sp_executesql @dropOtpPkSql;
END;

ALTER TABLE dbo.otp_tokens ALTER COLUMN id NVARCHAR(255) NOT NULL;
ALTER TABLE dbo.otp_tokens ALTER COLUMN code NVARCHAR(6) NOT NULL;

ALTER TABLE dbo.otp_tokens
    ADD CONSTRAINT PK_otp_tokens PRIMARY KEY (id);

ALTER TABLE dbo.rawmaterials ALTER COLUMN code NVARCHAR(255) NULL;
ALTER TABLE dbo.rawmaterials ALTER COLUMN name NVARCHAR(255) NULL;
ALTER TABLE dbo.rawmaterials ALTER COLUMN unit NVARCHAR(255) NULL;
ALTER TABLE dbo.rawmaterials ALTER COLUMN category NVARCHAR(255) NULL;

ALTER TABLE dbo.shiftsessions ALTER COLUMN pos_register_id NVARCHAR(255) NULL;
ALTER TABLE dbo.staffschedules ALTER COLUMN pos_register_id NVARCHAR(255) NULL;

ALTER TABLE dbo.stocktransactions ALTER COLUMN reason NVARCHAR(255) NULL;

ALTER TABLE dbo.stores ALTER COLUMN name NVARCHAR(255) NULL;
ALTER TABLE dbo.stores ALTER COLUMN address NVARCHAR(255) NULL;
ALTER TABLE dbo.stores ALTER COLUMN phone NVARCHAR(255) NULL;

ALTER TABLE dbo.systemconfigs ALTER COLUMN config_key NVARCHAR(255) NULL;
ALTER TABLE dbo.systemconfigs ALTER COLUMN config_value NVARCHAR(255) NULL;
ALTER TABLE dbo.systemconfigs ALTER COLUMN scope NVARCHAR(255) NULL;
ALTER TABLE dbo.systemconfigs ALTER COLUMN updated_by NVARCHAR(255) NULL;

ALTER TABLE dbo.users ALTER COLUMN employee_id NVARCHAR(255) NULL;
ALTER TABLE dbo.users ALTER COLUMN username NVARCHAR(255) NULL;
ALTER TABLE dbo.users ALTER COLUMN password_hash NVARCHAR(255) NULL;
ALTER TABLE dbo.users ALTER COLUMN full_name NVARCHAR(255) NULL;
ALTER TABLE dbo.users ALTER COLUMN email NVARCHAR(255) NULL;
ALTER TABLE dbo.users ALTER COLUMN phone NVARCHAR(255) NULL;
ALTER TABLE dbo.users ALTER COLUMN attendance_pin NVARCHAR(255) NULL;

ALTER TABLE dbo.vouchers ALTER COLUMN code NVARCHAR(255) NULL;
ALTER TABLE dbo.vouchers ALTER COLUMN description NVARCHAR(250) NULL;