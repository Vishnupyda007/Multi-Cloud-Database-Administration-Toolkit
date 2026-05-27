SELECT
    relname AS "Table Name",
    pg_size_pretty(pg_relation_size(relid)) as "Table Size",
    heap_blks_read AS "Heap Blocks Read",
    heap_blks_hit AS "Heap Blocks Hit (in-memory)",
    idx_blks_read AS "Index Blocks Read",
    idx_blks_hit AS "Index Blocks Hit (in-memory)"
FROM
    pg_statio_user_tables
ORDER BY
    (heap_blks_read + idx_blks_read) DESC
LIMIT 20;
