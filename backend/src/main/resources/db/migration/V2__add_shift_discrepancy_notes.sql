IF COL_LENGTH('dbo.shiftsessions', 'discrepancy_notes') IS NULL
BEGIN
    ALTER TABLE dbo.shiftsessions
    ADD discrepancy_notes NVARCHAR(1000) NULL;
END;