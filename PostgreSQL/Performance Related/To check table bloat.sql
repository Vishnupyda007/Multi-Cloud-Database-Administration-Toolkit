-----------------to check Table Bloating-----------------

SELECT
    current_database(),
    n.nspname AS schemaname,
    c.relname AS tablename,
    ROUND((c.reltuples / (
        CASE
            WHEN c.relpages = 0 THEN 1
            ELSE c.relpages
        END
    ))::numeric, 2) AS tuples_per_page,
    ROUND(c.reltuples::numeric) AS row_count,
    pg_size_pretty(pg_total_relation_size(c.oid)) AS total_size,
    pg_size_pretty(pg_relation_size(c.oid)) AS table_size,
    pg_size_pretty(pg_indexes_size(c.oid)) AS index_size,

    -- Bloat size calculation with the explicit ::bigint cast
    pg_size_pretty(
        (CASE
            WHEN c.relpages > 0 AND c.reltuples > 0 THEN
                (c.relpages - CEIL(c.reltuples / (
                    (c.relpages * 8192.0 - c.relpages * 24) /
                    (
                        SELECT avg_width
                        FROM pg_stats s
                        WHERE s.tablename = c.relname AND s.schemaname = n.nspname
                        LIMIT 1
                    )
                ))) * 8192
            ELSE 0
        END)::bigint  -- <--- THE FIX IS HERE
    ) AS bloat_size,

    -- Bloat percentage calculation (this one is fine as it deals with percentages)
    ROUND(
        (CASE
            WHEN c.relpages > 0 AND c.reltuples > 0 THEN
                100 * (c.relpages - CEIL(c.reltuples / (
                    (c.relpages * 8192.0 - c.relpages * 24) /
                    (
                        SELECT avg_width
                        FROM pg_stats s
                        WHERE s.tablename = c.relname AND s.schemaname = n.nspname
                        LIMIT 1
                    )
                ))) / c.relpages
            ELSE 0
        END)::numeric, 2
    ) AS bloat_percentage
FROM
    pg_class c
JOIN
    pg_namespace n ON n.oid = c.relnamespace
WHERE
    c.relkind = 'r'
    AND n.nspname NOT IN ('information_schema', 'pg_catalog', 'pg_toast')
ORDER BY
    -- The ORDER BY clause must also have the cast to sort correctly
    (CASE
        WHEN c.relpages > 0 AND c.reltuples > 0 THEN
            (c.relpages - CEIL(c.reltuples / (
                (c.relpages * 8192.0 - c.relpages * 24) /
                (
                    SELECT avg_width
                    FROM pg_stats s
                    WHERE s.tablename = c.relname AND s.schemaname = n.nspname
                    LIMIT 1
                )
            ))) * 8192
        ELSE 0
    END) DESC;




--------------------or -------------------------------------


WITH constants AS (
  SELECT current_setting('block_size')::numeric AS bs, 23 AS hdr, 4 AS ma
),
tables_with_fillfactor AS (
  SELECT
    *,
    COALESCE(
      (SELECT (SUBSTRING(unnest(reloptions) FROM 'fillfactor=([0-9]+)')::smallint)),
      100 -- Default fillfactor for tables is 100
    ) AS fillfactor
  FROM pg_class
),
bloat_info AS (
  SELECT
    tbl.oid,
    tbl.relname,
    N.nspname,
    tbl.reltuples,
    (
      tbl.relpages -
      CEIL(tbl.reltuples / ((constants.bs - constants.hdr) / (tbl.fillfactor / 100.0)))
    ) * constants.bs AS "Total Bloat"
  FROM tables_with_fillfactor tbl
  JOIN pg_namespace N ON N.oid = tbl.relnamespace
  JOIN constants ON true
  WHERE tbl.relkind = 'r' AND tbl.relpages > 0
)
SELECT
  nspname as "Schema",
  relname as "Table",
  round(reltuples::numeric) as "Row Count",

  -- THE FIX IS HERE: Cast the result to bigint before passing to pg_size_pretty
  pg_size_pretty(
    (CASE WHEN "Total Bloat" < 0 THEN 0 ELSE "Total Bloat" END)::bigint
  ) as "Bloat",

  -- This calculation is for a percentage, so it's fine.
  round(
    100 * (CASE WHEN "Total Bloat" < 0 THEN 0 ELSE "Total Bloat" END) /
    -- Add a check to prevent division by zero for completely empty/bloated tables
    NULLIF(pg_total_relation_size(oid), 0)
  ) || '%' as "Bloat Ratio"
FROM
  bloat_info
ORDER BY
  "Total Bloat" DESC;



-------
Bloat / bloat_size	The script's estimate of the total amount of wasted space in the table that could potentially be reclaimed.	This is your primary action indicator. If this number is measured in megabytes for a small table, it might be fine. If it's measured in gigabytes, it's a major issue. Sort your results by this column in descending order.




Bloat Ratio / bloat_percentage	The estimated percentage of the table's total physical size on disk that is just wasted space (bloat).	This provides crucial context. A Bloat of 500 MB might seem large, but if the table is 1 TB, the Bloat Ratio is tiny and not a concern. However, a 500 MB bloat on a 1 GB table means a 50% bloat ratio, which is a severe problem.
The Golden Rule for Action
You have a significant bloat problem that requires action if you see either of the following:

High Bloat Ratio: A table has a bloat ratio greater than 20-30%. This means a significant portion of the table is empty space.

High Absolute Bloat: A table has a bloat_size in the multiple gigabytes. Even if the ratio is low, reclaiming several gigabytes of disk space is often worth the effort.

