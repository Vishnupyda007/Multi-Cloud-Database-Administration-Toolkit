
WITH db_sizes AS (
    SELECT datname AS database_name,
           pg_database_size(datname) AS size_bytes
    FROM pg_database
    WHERE datistemplate = false
),
summary AS (
    SELECT SUM(size_bytes) AS total_used_bytes
    FROM db_sizes
)
SELECT
    1024::numeric AS total_capacity_gb,  -- <-- put your instance storage limit here
    ROUND(summary.total_used_bytes / 1024 / 1024 / 1024, 2) AS consumed_capacity_gb,
    ROUND(1024::numeric - (summary.total_used_bytes / 1024 / 1024 / 1024), 2) AS available_capacity_gb
FROM summary;


------------------------

SELECT pg_size_pretty(pg_database_size('OneC_4653')) AS db_size;




SELECT datname AS database_name,
       pg_size_pretty(pg_database_size(datname)) AS size
FROM pg_database
ORDER BY pg_database_size(datname) DESC;


---------------------------------


SELECT
    datname AS database_name,
    ROUND(pg_database_size(datname) / 1024 / 1024 / 1024, 2) AS size_gb,
    pg_size_pretty(pg_database_size(datname)) AS size_pretty
FROM pg_database
WHERE datistemplate = false
ORDER BY pg_database_size(datname) DESC;
