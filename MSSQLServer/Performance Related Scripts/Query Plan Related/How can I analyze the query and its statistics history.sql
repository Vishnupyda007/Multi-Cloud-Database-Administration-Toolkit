Analyzing a query's history is key to understanding *why* a regression happened. You need to become a detective, and your primary crime scene is the **Query Store**.

Here is a step-by-step guide on how to analyze a query's performance and statistics history.

---

### Step 1: Identify Your Target Query

First, you need the `query_id` of the query you want to investigate. You likely already have this from the previous RCA, but if not, you can find it by looking for the query text in the Query Store.

```sql
SELECT
    q.query_id,
    qt.query_sql_text
FROM sys.query_store_query AS q
JOIN sys.query_store_query_text AS qt
    ON q.query_text_id = qt.query_text_id
WHERE
    qt.query_sql_text LIKE '%Some unique text from your query%';
```

---

### Step 2: Analyze Plan History and Performance Variation

Once you have the `query_id`, you can see all the different execution plans that have been generated for it over time. This is the most crucial view for spotting a regression.

```sql
SELECT
    p.plan_id,
    p.query_id,
    q.object_id,
    rs.avg_duration / 1000 AS avg_duration_ms,
    rs.avg_cpu_time / 1000 AS avg_cpu_time_ms,
    rs.avg_logical_io_reads,
    rs.count_executions,
    p.initial_compile_start_time,
    p.last_execution_time,
    IIF(p.is_forced_plan = 1, 'FORCED', 'NOT FORCED') as is_forced
FROM sys.query_store_plan AS p
JOIN sys.query_store_runtime_stats AS rs
    ON p.plan_id = rs.plan_id
JOIN sys.query_store_query AS q
    ON p.query_id = q.query_id
WHERE
    p.query_id = <your_query_id>
ORDER BY
    p.last_execution_time DESC;
```

**How to Analyze the Results:**

1.  **Look for Multiple `plan_id`s:** If you see more than one plan, it means the optimizer has changed its mind about how to run the query.
2.  **Compare Performance Metrics:**
    *   Find your "good" plan (the one with the low `avg_duration_ms`).
    *   Find your "regressed" plan (the one with the high `avg_duration_ms`).
3.  **Check the Timestamps:** Note the `last_execution_time` for the good plan and the `initial_compile_start_time` for the regressed plan. This tells you **when** the regression happened. What changed in your environment during that time window? (e.g., a code deployment, index maintenance, etc.).

---

### Step 3: Compare the Execution Plans Visually

Now that you've identified the good plan and the bad plan, you need to understand *what* is different about them.

1.  **Get the `plan_id`s:** Note the `plan_id` for your good plan and your bad plan from the query in Step 2.
2.  **Open in SSMS:** In SQL Server Management Studio (SSMS), you can use the **Query Store** UI to visually compare the plans.
    *   Navigate to your database -> **Query Store** -> **Top Resource Consuming Queries**.
    *   Find your query and on the right-hand side, you will see the different plans.
    *   You can select two plans and click the **Compare** button. This will show you a side-by-side visual representation, highlighting the differences.

**What to Look For in the Plan Comparison:**

*   **Different Join Types:** Did a fast `Nested Loops` join change to a slow `Hash Match` join?
*   **Index Usage:** Is the good plan using an `Index Seek` while the bad plan is doing a full `Clustered Index Scan`? This is a classic sign of a problem.
*   **Cardinality Estimates:** Hover over the arrows connecting the operators. You will see an "Estimated Number of Rows" vs. an "Actual Number of Rows." If these numbers are wildly different in the bad plan, it's a huge clue that your statistics were out of date.

---

### Step 4: Investigate Statistics History

While SQL Server doesn't store a version history of the *statistics object itself*, you can infer its state by looking at the plan.

1.  **Find the Statistics Used by the Plan:** In the graphical execution plan from Step 3, right-click on an operator (like an `Index Seek`) and go to **Properties**. In the properties pane, you can often find information about the statistics objects that were used for cardinality estimation.

2.  **Check Current Statistics:** Once you have the name of the statistics object and the table it belongs to, you can view its current state.

    ```sql
    -- Check when statistics were last updated for a table
    SELECT
        st.name AS statistics_name,
        sp.last_updated
    FROM sys.stats AS st
    CROSS APPLY sys.dm_db_stats_properties(st.object_id, st.stats_id) AS sp
    WHERE
        st.object_id = OBJECT_ID('YourTableName');

    -- View the actual histogram (the data inside the statistic)
    DBCC SHOW_STATISTICS('YourTableName', 'StatisticsName');
    ```

**How to Analyze:**

*   If the `last_updated` date for a key statistic is just before the regression occurred, it's possible that the update process created a less accurate statistic.
*   If the `last_updated` date is very old, it strongly suggests the statistic was stale, leading the optimizer to make a bad decision.
*   Look at the histogram from `DBCC SHOW_STATISTICS`. Does the distribution shown in the histogram reflect the actual data in your table? If not, the statistic is misleading the optimizer.