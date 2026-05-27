To help you analyze **forced plans** in your SQL Server environment, we can use **Query Store** to identify:

1. Which queries currently have forced plans.
2. How those forced plans are performing compared to other plans.
3. Whether any forced plans are underperforming or outdated.

---

### ✅ Step-by-Step Analysis Script

Here’s a SQL script that gives you a detailed view of forced plans:

```sql
SELECT 
    q.query_id,
    qt.query_sql_text,
    p.plan_id,
    p.is_forced_plan,
    p.force_failure_count,
    rs.avg_duration,
    rs.avg_cpu_time,
    rs.avg_logical_io_reads,
    rs.execution_type_desc,
    rs.count_executions,
    p.last_execution_time
FROM sys.query_store_query q
JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan p ON q.query_id = p.query_id
JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
WHERE p.is_forced_plan = 1
ORDER BY rs.avg_duration DESC;
```

---

### 🔍 What This Tells You

- **`is_forced_plan = 1`**: Filters only forced plans.
- **`force_failure_count`**: Shows if SQL Server failed to apply the forced plan.
- **`avg_duration`, `avg_cpu_time`, `avg_logical_io_reads`**: Helps you assess performance.
- **`last_execution_time`**: Indicates if the plan is still in use.

---

### 🧠 How to Use This

- Look for **high duration or CPU time**: These may be candidates for unforcing.
- Check **`force_failure_count` > 0**: SQL Server is struggling to apply the plan.
- Compare with other plans for the same `query_id` (if available) to see if better plans exist.

---

Would you like a version of this script that exports the results to a table or Excel file for easier review? Or should we build a dashboard-style report using this data?




--------------------------------------

After analyzing forced plans using Query Store, the next steps depend on what the analysis reveals. Here's a structured approach to guide your decisions:

---

### ✅ **1. Identify Underperforming Forced Plans**

Look for:
- High `avg_duration`, `avg_cpu_time`, or `avg_logical_io_reads`
- High `force_failure_count`
- Plans not executed recently (`last_execution_time` is old)

➡️ **Next Step**: Consider **unforcing** these plans using:

```sql
EXEC sys.sp_query_store_unforce_plan 
    @query_id = <query_id>, 
    @plan_id = <plan_id>;
```

---

### ✅ **2. Compare with Alternative Plans**

Use this query to see all plans for a query:

```sql
SELECT 
    p.plan_id, 
    p.is_forced_plan, 
    rs.avg_duration, 
    rs.avg_cpu_time, 
    rs.count_executions
FROM sys.query_store_plan p
JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
WHERE p.query_id = <your_query_id>
ORDER BY rs.avg_duration;

---or-------------

SELECT p.query_id,
    p.plan_id, 
    p.is_forced_plan, 
    rs.avg_duration, 
    rs.avg_cpu_time, 
    rs.count_executions,
    p.last_force_failure_reason,
    p.force_failure_count,
    p.last_execution_time
FROM sys.query_store_plan p
JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
WHERE p.query_id = 11002520
ORDER BY rs.avg_duration;

```

➡️ **Next Step**: If a non-forced plan performs better, consider **forcing that one instead**:

```sql
EXEC sys.sp_query_store_force_plan 
    @query_id = <query_id>, 
    @plan_id = <better_plan_id>;
```

---

### ✅ **3. Update Statistics and Re-Evaluate**

If plans are outdated due to stale stats:

```sql
UPDATE STATISTICS <table_name>;
```

➡️ **Next Step**: Unforce the plan and let SQL Server choose a new one. Monitor performance.

---

### ✅ **4. Use Query Hints or Recompilation**

If parameter sensitivity is an issue:

- Use `OPTION (RECOMPILE)` in the procedure or query.
- Or use `OPTIMIZE FOR` hints to guide the optimizer.

---

### ✅ **5. Monitor After Changes**

After unforcing or changing plans:
- Monitor performance using Query Store.
- Set alerts or use Extended Events for regressions.

---

Would you like a script that automates the detection of underperforming forced plans and suggests actions?