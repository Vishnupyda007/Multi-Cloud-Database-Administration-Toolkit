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
  AND NOW() - query_start > INTERVAL '1 minutes' 
  --or NOW() - query_start > INTERVAL '1 seconds'
ORDER BY duration DESC;



-----------------------------------



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



