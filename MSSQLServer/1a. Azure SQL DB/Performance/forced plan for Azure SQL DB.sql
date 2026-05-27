SELECT
    qt.query_text_id,
    qt.query_sql_text,
    q.query_id,
    rs.plan_id,
    fpl.force_failure_count,
    fpl.last_force_failure_reason,
    fpl.last_force_failure_time,
    fpl.force_plan_state,
    CASE fpl.force_plan_state
        WHEN 0 THEN 'Not Forced'
        WHEN 1 THEN 'Forced'
        WHEN 2 THEN 'Failed to Force'
        WHEN 3 THEN 'Force Throttled'
        ELSE 'Unknown'
    END AS force_plan_state_desc,
    fpl.last_good_plan_id,
    rs_lgp.plan_id AS last_good_plan_plan_id,
    qpe_lgp.query_plan AS last_good_plan_query_plan,
    qpe_lgp.query_plan_hash AS last_good_plan_query_plan_hash
FROM sys.query_store_query_text AS qt
INNER JOIN sys.query_store_query AS q
    ON qt.query_text_id = q.query_text_id
INNER JOIN sys.query_store_plan AS p
    ON q.query_id = p.query_id
INNER JOIN sys.query_store_runtime_stats AS rs
    ON p.plan_id = rs.plan_id
LEFT JOIN sys.query_store_forced_plan AS fpl
    ON p.plan_id = fpl.plan_id
LEFT JOIN sys.query_store_plan AS p_lgp
    ON fpl.last_good_plan_id = p_lgp.plan_id
LEFT JOIN sys.query_store_runtime_stats AS rs_lgp
    ON p_lgp.plan_id = rs_lgp.plan_id
LEFT JOIN sys.query_store_query_plan AS qpe_lgp
    ON p_lgp.plan_id = qpe_lgp.plan_id
WHERE
    fpl.force_plan_state = 1 -- To filter for queries with a forced plan
    OR q.query_id = 7471366
    OR p.plan_id = 7056898;