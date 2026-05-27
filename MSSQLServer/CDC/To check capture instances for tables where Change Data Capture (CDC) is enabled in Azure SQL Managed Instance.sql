To check **capture instances** for tables where Change Data Capture (CDC) is enabled in **Azure SQL Managed Instance**, you can query the system tables provided by CDC:

***

### ✅ **Query to List All Capture Instances**

```sql
SELECT capture_instance,
       source_object_id,
       source_schema,
       source_table,
       start_lsn,
       end_lsn
FROM sys.cdc_capture_instances;
```

**What it shows:**

*   `capture_instance` → The name of the CDC instance (usually `<schema>_<table>`).
*   `source_schema` and `source_table` → Original table being tracked.
*   `start_lsn` / `end_lsn` → LSN range for the capture instance.

***

### ✅ **Check Which Tables Have CDC Enabled**

```sql
SELECT name AS table_name,
       is_tracked_by_cdc
FROM sys.tables
WHERE is_tracked_by_cdc = 1;
```

***

### ✅ **Check Database-Level CDC Status**

```sql
SELECT is_cdc_enabled FROM sys.databases WHERE name = DB_NAME();
```

***

### ✅ **Check Change Tables for a Specific Capture Instance**

```sql
SELECT * FROM cdc.change_tables;
```

This shows the mapping between capture instances and their associated change tables.

***

👉 Do you want me to **give you a combined script** that:

*   Lists all capture instances,
*   Shows CDC-enabled tables,
*   And includes a quick disable command template for each instance?
