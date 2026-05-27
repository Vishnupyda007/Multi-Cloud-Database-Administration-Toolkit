Here’s a **wholesome monitoring script for Cloud SQL (PostgreSQL)** that covers:

✅ CPU & Memory usage (via `pg_stat_activity` and `pg_stat_statements`)  
✅ High CPU-consuming queries  
✅ Databases consuming most resources  

---

### **Step 1: Enable pg_stat_statements**
Make sure the extension is enabled:
```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

---

### **Step 2: Monitoring Script**
```sql
-- 1. Active Sessions with CPU Time
SELECT 'ACTIVE_SESSIONS' AS section,
       pid,
       usename AS username,
       datname AS database,
       client_addr AS client_ip,
       application_name,
       state,
       query,
       backend_start,
       now() - backend_start AS session_duration
FROM pg_stat_activity
WHERE state = 'active'
ORDER BY session_duration DESC;

-- 2. Top CPU-Consuming Queries
SELECT 'TOP_CPU_QUERIES' AS section,
       query,
       calls,
       total_exec_time AS total_time_ms,
       mean_exec_time AS avg_time_ms,
       rows
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;

-- 3. Database-Level Resource Usage
SELECT 'DB_RESOURCE_USAGE' AS section,
       datname AS database,
       numbackends AS active_connections,
       xact_commit,
       xact_rollback,
       blks_read,
       blks_hit,
       tup_returned,
       tup_fetched,
       tup_inserted,
       tup_updated,
       tup_deleted
FROM pg_stat_database
ORDER BY numbackends DESC;
```

---

### ✅ **What This Does**
- **Active Sessions** → Shows current queries and duration.
- **Top CPU Queries** → From `pg_stat_statements`, sorted by total execution time.
- **Database Resource Usage** → From `pg_stat_database`, shows connections and I/O stats.

---

### ✅ **Optional: Memory Usage**
PostgreSQL doesn’t expose direct memory per query, but you can approximate by:
- Checking `work_mem`, `shared_buffers` settings.
- Monitoring via **Cloud SQL metrics** in GCP console.

---


PostgreSQL itself does **not expose OS-level CPU and memory usage** because it runs inside the Cloud SQL managed environment. To check **overall server CPU and memory usage percentage**, you have two main options:

---

### ✅ **Option 1: Use Cloud SQL Monitoring (Recommended)**
- Go to **Google Cloud Console → Cloud SQL → Your Instance → Monitoring**.
- Metrics available:
  - **CPU Utilization (%)**
  - **Memory Usage (%)**
  - **Disk I/O**
  - **Connections**
- You can also set **alerts** in **Cloud Monitoring** for thresholds (e.g., CPU > 80%).

---

### ✅ **Option 2: Query PostgreSQL for Active Workload**
While PostgreSQL cannot show OS-level CPU/memory, you can approximate resource-heavy queries using `pg_stat_statements`:

```sql
SELECT query,
       calls,
       total_exec_time AS total_time_ms,
       mean_exec_time AS avg_time_ms,
       rows
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;
```

This shows which queries are consuming the most CPU time.

---

### ✅ **Option 3: Use `pg_stat_activity` for Active Sessions**
```sql
SELECT pid,
       usename,
       datname,
       state,
       query,
       now() - backend_start AS duration
FROM pg_stat_activity
WHERE state = 'active'
ORDER BY duration DESC;
```

---

### ✅ **Why You Can’t Get Exact CPU/Memory from SQL**
- Cloud SQL runs PostgreSQL in a managed VM; OS metrics are exposed only via **Cloud Monitoring**, not SQL queries.
- For **real-time CPU/memory**, use:
  - **Cloud Monitoring API**
  - **Cloud SQL Insights**

---

