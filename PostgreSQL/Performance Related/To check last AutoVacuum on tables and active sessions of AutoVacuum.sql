------Last Autovacuum for the tables----
SELECT
    relname,
    last_autovacuum,
    last_autoanalyze,
    n_live_tup,
    n_dead_tup
FROM pg_stat_user_tables
ORDER BY last_autovacuum ASC NULLS FIRST;


---to check if any Active sessions reg AutoVacuuum
SELECT
    pid,
    datname,
    usename,
    state,
    query
FROM pg_stat_activity
WHERE query LIKE 'autovacuum: %';

