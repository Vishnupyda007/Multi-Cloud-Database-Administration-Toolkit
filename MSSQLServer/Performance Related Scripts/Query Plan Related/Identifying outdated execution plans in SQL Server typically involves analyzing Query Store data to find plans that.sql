Identifying **outdated execution plans** in SQL Server typically involves analyzing Query Store data to find plans that:

- Haven’t been used recently.
- Were created a long time ago.
- Are underperforming compared to newer plans for the same query.

---

### ✅ Query to Identify Potentially Outdated Plans

Here’s a SQL query to help you find such plans:

```sql
SELECT 
    q.query_id,
    qt.query_sql_text,
    p.plan_id,
    p.is_forced_plan,
    p.last_execution_time,
    p.creation_time,
    DATEDIFF(DAY, p.last_execution_time, GETDATE()) AS days_since_last_execution,
    rs.avg_duration,
    rs.avg_cpu_time,
    rs.count_executions
FROM sys.query_store_query q
JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan p ON q.query_id = p.query_id
JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
WHERE p.last_execution_time IS NOT NULL
ORDER BY days_since_last_execution DESC;
```

---

### 🔍 What to Look For

- **High `days_since_last_execution`**: Indicates the plan hasn’t been used recently.
- **Old `creation_time`**: Suggests the plan may not reflect current data or schema.
- **Low `count_executions`**: May indicate it's no longer relevant or optimal.
- **High `avg_duration` or `avg_cpu_time`**: Could be a sign of inefficiency.

---

### 🧠 Next Steps

- **Review alternative plans** for the same `query_id` to see if newer ones perform better.
- **Unforce outdated plans** if they are currently forced.
- **Update statistics** and allow SQL Server to recompile if needed.

Would you like a version of this query that filters only **forced plans** or exports the results for reporting?