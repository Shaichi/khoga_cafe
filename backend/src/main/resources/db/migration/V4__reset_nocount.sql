-- Reset SQL Server session row-count reporting after V3.
-- Hibernate expects INSERT/UPDATE statements to report the affected row count.
SET NOCOUNT OFF;
