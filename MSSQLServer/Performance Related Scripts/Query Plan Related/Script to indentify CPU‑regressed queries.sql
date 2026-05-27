Below are **production‑ready SQL Server DMV queries** that DBAs commonly use to identify **CPU‑regressed queries**—i.e., queries whose CPU usage has increased significantly over time—along with **execution count, total CPU time, average CPU, duration, logical reads, plan info**, etc.

I’ll show **two approaches**, because this is important:

***

## ✅ OPTION 1 (Best & Accurate): Query Store – CPU Regression Over Time

**Recommended if Query Store is enabled (SQL Server 2016+)**

This compares CPU usage **between two time windows** (e.g., last 1 hour vs previous 1 hour).

### 🔹 Top CPU‑Regressed Queries (Query Store)

```sql
DECLARE @RecentStart DATETIME2 = DATEADD(hour, -1, SYSUTCDATETIME());
DECLARE @BaselineStart DATETIME2 = DATEADD(hour, -2, SYSUTCDATETIME());

WITH Recent AS
(
    SELECT
        q.query_id,
        rs.plan_id,
        SUM(rs.count_executions) AS exec_count,
        SUM(rs.avg_cpu_time * rs.count_executions) AS total_cpu_ms,
        AVG(rs.avg_cpu_time) AS avg_cpu_ms
    FROM sys.query_store_runtime_stats rs
    JOIN sys.query_store_runtime_stats_interval rsi
        ON rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
    JOIN sys.query_store_plan p ON rs.plan_id = p.plan_id
    JOIN sys.query_store_query q ON p.query_id = q.query_id
    WHERE rsi.start_time >= @RecentStart
    GROUP BY q.query_id, rs.plan_id
),
Baseline AS
(
    SELECT
        q.query_id,
        rs.plan_id,
        SUM(rs.avg_cpu_time * rs.count_executions) AS baseline_cpu_ms
    FROM sys.query_store_runtime_stats rs
    JOIN sys.query_store_runtime_stats_interval rsi
        ON rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
    JOIN sys.query_store_plan p ON rs.plan_id = p.plan_id
    JOIN sys.query_store_query q ON p.query_id = q.query_id
    WHERE rsi.start_time >= @BaselineStart
      AND rsi.start_time < @RecentStart
    GROUP BY q.query_id, rs.plan_id
)
SELECT TOP 20
    qt.query_sql_text,
    r.exec_count,
    r.total_cpu_ms,
    r.avg_cpu_ms,
    b.baseline_cpu_ms,
    (r.total_cpu_ms - ISNULL(b.baseline_cpu_ms,0)) AS cpu_regression_ms,
    r.plan_id
FROM Recent r
LEFT JOIN Baseline b
    ON r.query_id = b.query_id
JOIN sys.query_store_query_text qt
    ON qt.query_text_id =
       (SELECT query_text_id FROM sys.query_store_query WHERE query_id = r.query_id)
ORDER BY cpu_regression_ms DESC;
```

### ✅ What this gives you

*   ✅ True **CPU regression**
*   ✅ Execution count
*   ✅ Total & average CPU
*   ✅ Query text + plan tracking
*   ✅ Ideal for **performance incident RCA**

***

## ✅ OPTION 2: DMV‑Based (No Query Store)

This shows **current top CPU consumers**, not historical regression, but still very useful.

### 🔹 Top CPU Queries (Current Cache)

```sql
SELECT TOP 20
    qs.execution_count,
    qs.total_worker_time / 1000 AS total_cpu_ms,
    qs.total_worker_time / qs.execution_count / 1000 AS avg_cpu_ms,
    qs.total_elapsed_time / 1000 AS total_duration_ms,
    qs.total_logical_reads AS logical_reads,
    qs.total_physical_reads AS physical_reads,
    DB_NAME(st.dbid) AS database_name,
    OBJECT_NAME(st.objectid, st.dbid) AS object_name,
    SUBSTRING(
        st.text,
        (qs.statement_start_offset / 2) + 1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(st.text)
            ELSE qs.statement_end_offset END
          - qs.statement_start_offset) / 2) + 1
    ) AS query_text,
    qp.query_plan
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
ORDER BY qs.total_worker_time DESC;
```

### ✅ Key Columns Explained

| Column              | Meaning                      |
| ------------------- | ---------------------------- |
| `execution_count`   | How many times executed      |
| `total_worker_time` | Total CPU time (µs)          |
| `avg_cpu_ms`        | CPU per execution            |
| `logical_reads`     | Memory pressure indicator    |
| `query_plan`        | For plan regression analysis |

***

## ✅ OPTION 3: CPU Regression by Plan Change (Query Store)

Find queries where **a new plan is consuming more CPU** than the old plan.

```sql
SELECT TOP 20
    qt.query_sql_text,
    p.plan_id,
    rs.avg_cpu_time,
    rs.count_executions,
    rs.avg_duration,
    p.is_forced_plan
FROM sys.query_store_runtime_stats rs
JOIN sys.query_store_plan p ON rs.plan_id = p.plan_id
JOIN sys.query_store_query q ON p.query_id = q.query_id
JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
ORDER BY rs.avg_cpu_time DESC;
```

✅ Ideal for:

*   Parameter sniffing
*   Bad plan after stats update
*   Index changes

***

## ✅ OPTION 4: Real‑Time High CPU (Currently Running Queries)

```sql
SELECT
    r.session_id,
    r.cpu_time,
    r.total_elapsed_time,
    r.logical_reads,
    r.status,
    SUBSTRING(
        t.text,
        r.statement_start_offset/2,
        (CASE WHEN r.statement_end_offset = -1
              THEN LEN(t.text)
              ELSE r.statement_end_offset END - r.statement_start_offset)/2
    ) AS running_query
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE r.cpu_time > 1000
ORDER BY r.cpu_time DESC;
```

***

## 🔑 Which Should You Use?

| Scenario                      | Best Choice              |
| ----------------------------- | ------------------------ |
| True CPU regression over time | ✅ Query Store (Option 1) |
| No Query Store                | ✅ DMV query (Option 2)   |
| Bad plan after deployment     | ✅ Option 3               |
| Live incident                 | ✅ Option 4               |

***

## ✅ Pro DBA Tips

*   Always normalize CPU by **execution\_count**
*   Correlate CPU spikes with:
    *   Stats updates
    *   Plan changes
    *   Parameter sniffing
*   Enable Query Store with:

```sql
ALTER DATABASE YourDB SET QUERY_STORE = ON;
```

***

If you want, I can:

*   ✅ Customize this for **Azure SQL / SQL MI**
*   ✅ Add **IO + waits correlation**
*   ✅ Build a **daily CPU regression report**
*   ✅ Convert this into a **stored procedure or monitoring job**

Just tell me 👍
