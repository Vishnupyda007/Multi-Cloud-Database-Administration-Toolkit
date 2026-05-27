Here's the complete script to **disable and enable CDC** for a table in Azure SQL Managed Instance:

```sql
-- ============================================================
-- CDC Enable / Disable for a Table — Azure SQL Managed Instance
-- ============================================================

-- -------------------------------------------------------
-- STEP 1: ENABLE CDC on the DATABASE (if not already)
--         Must be done before enabling on any table
-- -------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM sys.databases
    WHERE name = DB_NAME() AND is_cdc_enabled = 1
)
BEGIN
    EXEC sys.sp_cdc_enable_db;
    PRINT 'CDC enabled on database: ' + DB_NAME();
END
ELSE
    PRINT 'CDC already enabled on database: ' + DB_NAME();


-- -------------------------------------------------------
-- STEP 2: ENABLE CDC on a specific TABLE
-- -------------------------------------------------------
EXEC sys.sp_cdc_enable_table
    @source_schema          = N'dbo',               -- schema name
    @source_name            = N'your_table_name',   -- table name
    @role_name              = NULL,                  -- NULL = no gating role, any db_owner can query
    @capture_instance       = NULL,                  -- NULL = auto-names as schema_tablename
    @supports_net_changes   = 1,                     -- 1 = track net changes per row
    @index_name             = NULL,                  -- NULL = uses primary key by default
    @captured_column_list   = NULL,                  -- NULL = capture ALL columns
    @filegroup_name         = N'PRIMARY';            -- filegroup for CDC tables


-- -------------------------------------------------------
-- STEP 3: VERIFY CDC is enabled on the table
-- -------------------------------------------------------
SELECT
    t.name                          AS table_name,
    ct.capture_instance,
    ct.start_lsn,
    ct.index_name,
    ct.captured_columns             = (
        SELECT STRING_AGG(cc.column_name, ', ')
        FROM cdc.captured_columns cc
        WHERE cc.object_id = ct.source_object_id
    ),
    ct.supports_net_changes,
    ct.is_enabled
FROM cdc.change_tables ct
JOIN sys.tables t ON t.object_id = ct.source_object_id
WHERE t.name = N'your_table_name';


-- -------------------------------------------------------
-- STEP 4: DISABLE CDC on a specific TABLE
-- -------------------------------------------------------
EXEC sys.sp_cdc_disable_table
    @source_schema      = N'dbo',               -- schema name
    @source_name        = N'your_table_name',   -- table name
    @capture_instance   = N'dbo_your_table_name'; -- capture instance name
                                                  -- check from STEP 3 result


-- -------------------------------------------------------
-- STEP 5: DISABLE CDC on the DATABASE (if needed)
--         WARNING: This disables CDC for ALL tables in the DB
-- -------------------------------------------------------
-- EXEC sys.sp_cdc_disable_db;   -- uncomment only if you want to disable entire DB


-- -------------------------------------------------------
-- USEFUL: Check CDC status for ALL tables in the database
-- -------------------------------------------------------
SELECT
    s.name                          AS schema_name,
    t.name                          AS table_name,
    ct.capture_instance,
    ct.is_enabled,
    ct.supports_net_changes,
    ct.index_name,
    ct.start_lsn,
    ct.end_lsn
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
LEFT JOIN cdc.change_tables ct ON ct.source_object_id = t.object_id
WHERE ct.capture_instance IS NOT NULL
ORDER BY s.name, t.name;


-- -------------------------------------------------------
-- USEFUL: Check CDC jobs running in the background
-- -------------------------------------------------------
EXEC sys.sp_cdc_help_jobs;


-- -------------------------------------------------------
-- USEFUL: Check captured columns for a CDC-enabled table
-- -------------------------------------------------------
SELECT
    ct.capture_instance,
    cc.column_name,
    cc.column_type,
    cc.column_ordinal,
    cc.is_captured
FROM cdc.captured_columns cc
JOIN cdc.change_tables ct ON ct.object_id = cc.object_id
JOIN sys.tables t ON t.object_id = ct.source_object_id
WHERE t.name = N'your_table_name'
ORDER BY cc.column_ordinal;
```

---

### Key parameters explained — `sp_cdc_enable_table`

| Parameter | Value | Meaning |
|---|---|---|
| `@role_name` | `NULL` | No access gating — set a role name to restrict CDC query access |
| `@capture_instance` | `NULL` | Auto-generates as `schema_tablename` — max 2 instances per table |
| `@supports_net_changes` | `1` | Enables `cdc.fn_cdc_get_net_changes_*` in addition to all changes |
| `@captured_column_list` | `NULL` | Captures all columns — pass comma-separated list to limit columns |
| `@filegroup_name` | `PRIMARY` | Where CDC change tables are stored |

---

### Azure SQL MI specific notes

| Note | Detail |
|---|---|
| **SQL Agent required** | CDC relies on SQL Agent jobs (`cdc_capture`, `cdc_cleanup`) — ensure Agent is running on MI |
| **sysadmin or db_owner** | Required to run `sp_cdc_enable_db` and `sp_cdc_enable_table` |
| **Max 2 capture instances** | Each table supports max 2 CDC instances — useful for schema change transitions |
| **Disable before schema changes** | Always disable CDC before adding/dropping columns, then re-enable |
| **Retention** | Default retention is 3 days — adjust via `sp_cdc_change_job` |

---

### Adjust CDC retention period

```sql
-- Change retention to 5 days (in minutes: 5*24*60 = 7200)
EXEC sys.sp_cdc_change_job
    @job_type       = N'cleanup',
    @retention      = 7200;    -- minutes
```