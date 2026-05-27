SELECT
    n.nspname                                    AS table_schema,
    c.relname                                    AS table_name,
    c.reltuples::bigint                          AS row_count,

    -- Size WITHOUT indexes
    pg_table_size(c.oid)                         AS size_bytes_no_index,
    round(pg_table_size(c.oid) / 1024.0 / 1024.0, 2)        
                                                 AS size_mb_no_index,
    round(pg_table_size(c.oid) / 1024.0 / 1024.0 / 1024.0, 4)  
                                                 AS size_gb_no_index,

    -- Size WITH indexes (total)
    pg_total_relation_size(c.oid)                AS size_bytes_with_index,
    round(pg_total_relation_size(c.oid) / 1024.0 / 1024.0, 2)   
                                                 AS size_mb_with_index,
    round(pg_total_relation_size(c.oid) / 1024.0 / 1024.0 / 1024.0, 4) 
                                                 AS size_gb_with_index,

    -- Index size only
    pg_indexes_size(c.oid)                       AS index_size_bytes,
    round(pg_indexes_size(c.oid) / 1024.0 / 1024.0, 2)          
                                                 AS index_size_mb,
    round(pg_indexes_size(c.oid) / 1024.0 / 1024.0 / 1024.0, 4) 
                                                 AS index_size_gb,

    -- Human readable (bonus)
    pg_size_pretty(pg_table_size(c.oid))         AS pretty_size_no_index,
    pg_size_pretty(pg_total_relation_size(c.oid)) AS pretty_size_with_index,
    pg_size_pretty(pg_indexes_size(c.oid))       AS pretty_index_size

FROM
    pg_class c
JOIN
    pg_namespace n ON n.oid = c.relnamespace
WHERE
    c.relkind = 'r'
    AND n.nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY
    pg_total_relation_size(c.oid) DESC,
    c.relname;