To **disable Change Data Capture (CDC) for a specific table in Azure SQL Managed Instance**, you can use the built-in system stored procedure:

***

### ✅ **Steps**

1.  **Connect to your database** where CDC is enabled.

2.  **Run the following command**:

    ```sql
    EXEC sys.sp_cdc_disable_table
        @source_schema = N'<schema_name>',
        @source_name   = N'<table_name>',
        @capture_instance = N'<capture_instance_name>'; -- optional
    ```

    *   `@source_schema` → Schema of the table (e.g., `dbo`)
    *   `@source_name` → Table name
    *   `@capture_instance` → Optional; if you have multiple capture instances for the same table, specify which one to disable.

***

### ✅ **Example**

```sql
EXEC sys.sp_cdc_disable_table
    @source_schema = N'dbo',
    @source_name   = N'Orders';
```

This removes the CDC capture instance for that table and drops associated change tables and functions.

***

### ✅ **Verify**

Check if CDC is still enabled for the table:

```sql
SELECT * FROM sys.tables WHERE is_tracked_by_cdc = 1;
```

***

### ✅ **Important Notes**

*   Disabling CDC for a table does **not** disable CDC for the database. To fully disable CDC at the database level, use:
    ```sql
    EXEC sys.sp_cdc_disable_db;
    ```
*   Ensure no replication or ETL process depends on the CDC data before disabling.
*   Requires **db\_owner** or equivalent permissions.

***

👉 Do you want me to also give you:

*   A **script to disable CDC for all tables in a database**?
*   Or a **checklist for safely disabling CDC in production**?
