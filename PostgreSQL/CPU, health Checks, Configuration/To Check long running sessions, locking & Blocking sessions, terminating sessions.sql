-----------To Check long running sessions-----

SELECT 
    pid,
    usename AS username,
    application_name,
    client_addr,
    state,
    wait_event_type,
    wait_event,
    NOW() - query_start AS duration,
    query
FROM pg_stat_activity
WHERE state != 'idle'
  AND query_start IS NOT NULL
  AND NOW() - query_start > INTERVAL '5 minutes'
ORDER BY duration DESC;




-----------------------------with lock info and blocking details

SELECT 
    pid,
    usename                          AS username,
    application_name,
    client_addr,
    client_port,
    backend_start,
    query_start,
    state_change,
    state,
    wait_event_type,
    wait_event,
    NOW() - backend_start           AS total_session_duration,
    NOW() - query_start             AS current_query_duration,
    LEFT(query, 200)                AS query_snippet
FROM pg_stat_activity
WHERE state NOT IN ('idle', 'idle in transaction (aborted)')
  AND query_start IS NOT NULL
  AND NOW() - query_start > INTERVAL '1 minutes'
ORDER BY current_query_duration DESC;




----------------blocking queries


SELECT 
    blocked.pid                      AS blocked_pid,
    blocked.usename                  AS blocked_user,
    blocked.query                    AS blocked_query,
    NOW() - blocked.query_start      AS blocked_duration,
    blocking.pid                     AS blocking_pid,
    blocking.usename                 AS blocking_user,
    blocking.query                   AS blocking_query,
    NOW() - blocking.query_start     AS blocking_duration
FROM pg_stat_activity AS blocked
JOIN pg_stat_activity AS blocking 
    ON blocking.pid = ANY(pg_blocking_pids(blocked.pid))
WHERE cardinality(pg_blocking_pids(blocked.pid)) > 0
ORDER BY blocked_duration DESC;


---to get actual locks----------


SELECT 
    blocked.pid         AS blocked_pid,
    blocked.query       AS blocked_query,
    blocking.pid        AS blocking_pid,
    blocking.query      AS blocking_query
FROM pg_stat_activity blocked
JOIN pg_stat_activity blocking 
    ON blocking.pid = ANY(pg_blocking_pids(blocked.pid))
WHERE blocked.query LIKE '%vw_invoice_prediction_input%';

-----------------terminating


-- Graceful termination (waits for query to finish)
SELECT pg_cancel_backend(pid);

-- Forceful termination (immediate kill)
SELECT pg_terminate_backend(pid);

-- Kill all sessions running longer than 30 minutes
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE state != 'idle'
  AND NOW() - query_start > INTERVAL '30 minutes'
  AND pid <> pg_backend_pid();  -- exclude your own session