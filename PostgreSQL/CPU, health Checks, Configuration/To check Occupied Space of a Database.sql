PostgreSQL doesn’t track “free space per database” internally because storage is shared at the instance level. However, you can approximate it by:

*   **Occupied Size**: `pg_database_size(datname)`
*   **Free Size**: `Instance Allocated Storage – (Sum of all DB sizes + WAL size)`

Here’s an **SQL script** where you manually input your instance storage (e.g., 100 GB):

***

### ✅ **SQL Script**

```sql
-- Replace 100*1024*1024*1024 with your instance size in bytes (100 GB example)
WITH instance AS (
    SELECT 100*1024*1024*1024 AS instance_bytes -- 100 GB
),
db_info AS (
    SELECT datname AS database_name,
           pg_database_size(datname) AS occupied_bytes
    FROM pg_database
    WHERE datistemplate = false
),
wal_info AS (
    SELECT pg_wal_lsn_diff(pg_current_wal_lsn(), '0/0') AS wal_bytes
),
totals AS (
    SELECT SUM(occupied_bytes) AS total_db_bytes FROM db_info
)
SELECT
    database_name,
    pg_size_pretty(occupied_bytes) AS occupied_size,
    pg_size_pretty(
        (SELECT instance_bytes FROM instance)
        - occupied_bytes
        - (SELECT wal_bytes FROM wal_info)
    ) AS approx_free_space
FROM db_info
ORDER BY occupied_bytes DESC;
```

***

### ✅ **How It Works**

*   `instance_bytes` → Your allocated storage in bytes.
*   `occupied_bytes` → Actual DB size.
*   `wal_bytes` → WAL log size.
*   `approx_free_space` → Remaining space after subtracting DB + WAL.

***

⚠ **Note**: This is an approximation because:

*   Free space is at the instance level, not per DB.
*   PostgreSQL doesn’t reclaim space immediately after deletes (requires VACUUM).

***

👉 Do you want me to **extend this script** to also:
✔ Show **total occupied space across all DBs**  
✔ Include **WAL size and remaining instance free space** in one summary row?  
Or keep it per-database only?



-----------------------------

PostgreSQL (including Cloud SQL) does **not** directly expose “occupied vs free space” per database because storage is managed at the instance level, not per database. However, we can approximate:

***

### ✅ **Occupied Size**

*   This is the actual size of the database:  
    `pg_database_size(datname)` → gives occupied space in bytes.

***

### ✅ **Free Size**

*   Cloud SQL allocates storage at the **instance level**. Free space =  
    **Instance allocated storage – sum of all database sizes – WAL size – overhead**.

You can calculate this using:

1.  **Database sizes** from `pg_database_size()`.
2.  **Instance storage limit** from Cloud SQL settings (e.g., 100 GB).
3.  **WAL size** from `pg_wal_lsn_diff()`.

***

### ✅ **Combined Query for Occupied Size per DB**

```sql
WITH db_info AS (
    SELECT datname AS database_name,
           pg_database_size(datname) AS occupied_bytes
    FROM pg_database
    WHERE datistemplate = false
),
wal_info AS (
    SELECT pg_wal_lsn_diff(pg_current_wal_lsn(), '0/0') AS wal_bytes
)
SELECT
    database_name,
    pg_size_pretty(occupied_bytes) AS occupied_size,
    pg_size_pretty((SELECT wal_bytes FROM wal_info)) AS wal_size
FROM db_info
ORDER BY occupied_bytes DESC;
```

***

### ✅ **Free Space Calculation**

You need to know **instance allocated storage** (e.g., 100 GB). Then:

    Free Space = Instance Storage - (Sum of all DB sizes + WAL size)

***

👉 Do you want me to give you:
✔ **A full SQL + Python script** that connects to Cloud SQL, fetches instance storage from GCP API, calculates occupied vs free space per DB, and outputs in MB/GB?  
✔ Or just **SQL approximation** assuming you manually input instance size?

Which one do you prefer? **(Full automation or SQL-only?)**



Here’s a **single query script** that gives you:

*   **Database size** (in MB)
*   **Data size** (tables + indexes)
*   **WAL (log) size** estimate

***

### ✅ **PostgreSQL Query for Cloud SQL**

```sql
WITH db_info AS (
    SELECT
        datname AS database_name,
        pg_database_size(datname) AS db_size_bytes
    FROM pg_database
    WHERE datistemplate = false
),
wal_info AS (
    SELECT pg_wal_lsn_diff(pg_current_wal_lsn(), '0/0') AS wal_bytes
)
SELECT
    database_name,
    pg_size_pretty(db_size_bytes) AS database_size,
    pg_size_pretty((SELECT wal_bytes FROM wal_info)) AS wal_size
FROM db_info
ORDER BY db_size_bytes DESC;
```

***

### ✅ **Explanation**

*   `pg_database_size(datname)` → Size of each database.
*   `pg_wal_lsn_diff()` → WAL size since start (approx).
*   `pg_size_pretty()` → Converts bytes to MB/GB.

***

### ✅ **To Get Data File Size (Tables + Indexes)**

Run this for each table:

```sql
SELECT
    schemaname,
    relname AS table_name,
    pg_size_pretty(pg_total_relation_size(relid)) AS table_size
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC;
```

***

Do you want me to **combine everything into one automated script** that:
✔ Runs for **all databases**  
✔ Lists **database size, WAL size, and top 10 largest tables per DB**  
✔ Outputs in **MB/GB format**

I can give you a **ready-to-run SQL script** or a **Python automation script** for Cloud SQL. Which one do you prefer? **(SQL only or Python automation?)**




In **Cloud SQL for PostgreSQL**, you can check database size, data file size, and log file size using SQL queries and the Cloud SQL interface. Here’s how:

***

### ✅ **1. Check Database Size (in MB or GB)**

PostgreSQL provides the `pg_database_size()` function:

```sql
-- Size of a specific database in MB
SELECT pg_size_pretty(pg_database_size('your_database_name')) AS database_size;
```

*   `pg_size_pretty()` converts bytes into human-readable format (MB, GB).
*   Replace `your_database_name` with your actual DB name.

***

### ✅ **2. Check All Databases with Sizes**

```sql
SELECT datname AS database_name,
       pg_size_pretty(pg_database_size(datname)) AS size
FROM pg_database
ORDER BY pg_database_size(datname) DESC;
```

***

### ✅ **3. Check Data File Size (Tables + Indexes)**

For a specific schema or table:

```sql
-- Size of a table including indexes
SELECT pg_size_pretty(pg_total_relation_size('schema.table_name')) AS table_size;
```

For entire database objects:

```sql
SELECT pg_size_pretty(pg_tablespace_size('pg_default')) AS default_tablespace_size;
```

***

### ✅ **4. Check WAL (Log) File Size**

PostgreSQL uses **WAL (Write-Ahead Log)** files. To check WAL usage:

```sql
SELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), '0/0')) AS wal_size;
```

Or check the directory size (requires superuser or monitoring role):

```sql
SELECT pg_size_pretty(pg_ls_dir('pg_wal'));
```

***

### ✅ **Cloud SQL Console**

*   Go to **Google Cloud Console → SQL → Your Instance → Monitoring**.
*   You’ll see **Storage usage** (data + WAL logs) and **database size**.

***

Do you want me to:
✔ Give you **a single query that lists database size, data size, and WAL size together**?  
✔ Or **a script to automate this for all databases in your Cloud SQL instance**?
