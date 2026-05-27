-- Central, cross-database verification report (uses host/port/user/password)
-- Run this in the `postgres` database (the DB that hosts maintenance.stats_update_run_log)
set time zone 'Asia/Kolkata';
-- 0) Ensure dblink
CREATE EXTENSION IF NOT EXISTS dblink;

-- 1) Collect current index state + fragmentation + usage + maintenance + bloat from ALL chosen DBs
DO $$
DECLARE
    -- >>>> EDIT these to match your environment
    db_host        TEXT := '10.75.154.5';
    db_port        INT  := 5432;
    admin_user     TEXT := 'postgres';
    admin_password TEXT := 'gqNh+9@9mfe@4`y5';

    -- Scope of databases to scan
    include_dbs text[] := NULL;  -- e.g., ARRAY['db1','db2'] or NULL for all
    exclude_dbs text[] := ARRAY['postgres','template0','template1','cloudsqladmin'];  -- add more if needed

    -- Bloat collection guards (to avoid scanning tiny relations)
    min_index_bytes bigint := 1024*1024;   -- 1 MiB
    min_table_bytes bigint := 1024*1024;   -- 1 MiB

    dbname   text;
    conninfo text;
BEGIN
    ----------------------------------------------------------------------
    -- Temp tables: drop-on-commit work surfaces
    ----------------------------------------------------------------------
    -- live index state (size + relfilenode + parent table)
    CREATE TEMP TABLE IF NOT EXISTS tmp_index_state (
        dbname          text,
        schema          text,
        index_name      text,
        index_type      text,
        table_name      text,
        size_bytes      bigint,
        size_pretty     text,
        relfilenode     oid
    ) ON COMMIT DROP;

    -- fragmentation diagnostics (pgstatindex)
    CREATE TEMP TABLE IF NOT EXISTS tmp_index_diag (
        dbname              text,
        schema              text,
        index_name          text,
        leaf_fragmentation  double precision,
        avg_leaf_density    double precision
    ) ON COMMIT DROP;

    -- index usage (pg_stat_user_indexes)
    CREATE TEMP TABLE IF NOT EXISTS tmp_index_usage (
        dbname         text,
        schema         text,
        index_name     text,
        idx_scan       bigint,
        idx_tup_read   bigint,
        idx_tup_fetch  bigint,
        last_idx_scan  timestamptz
    ) ON COMMIT DROP;

    -- table maintenance + sizes (pg_stat_all_tables + size funcs)
    CREATE TEMP TABLE IF NOT EXISTS tmp_table_maint (
        dbname              text,
        schema              text,
        table_name          text,
        last_vacuum         timestamptz,
        last_autovacuum     timestamptz,
        last_analyze        timestamptz,
        last_autoanalyze    timestamptz,
        n_dead_tup          bigint,
        n_live_tup          bigint,
        n_mod_since_analyze bigint,
        table_total_bytes   bigint,
        table_table_bytes   bigint,
        table_indexes_bytes bigint
    ) ON COMMIT DROP;

    -- index bloat (pgstattuple.free_percent)
    CREATE TEMP TABLE IF NOT EXISTS tmp_index_bloat (
        dbname           text,
        schema           text,
        index_name       text,
        idx_free_percent double precision
    ) ON COMMIT DROP;

    -- table bloat (pgstattuple.free_percent)
    CREATE TEMP TABLE IF NOT EXISTS tmp_table_bloat (
        dbname           text,
        schema           text,
        table_name       text,
        tbl_free_percent double precision
    ) ON COMMIT DROP;

    -- Clear if re-running
    TRUNCATE tmp_index_state;
    TRUNCATE tmp_index_diag;
    TRUNCATE tmp_index_usage;
    TRUNCATE tmp_table_maint;
    TRUNCATE tmp_index_bloat;
    TRUNCATE tmp_table_bloat;

    ----------------------------------------------------------------------
    -- Iterate all selected DBs
    ----------------------------------------------------------------------
    FOR dbname IN
        SELECT datname
        FROM pg_database
        WHERE datallowconn
          AND NOT datistemplate
          AND (include_dbs IS NULL OR datname = ANY(include_dbs))
          AND (exclude_dbs IS NULL OR NOT (datname = ANY(exclude_dbs)))
        ORDER BY datname
    LOOP
        BEGIN
            -- Build a fully quoted libpq conninfo string: key='value'
            conninfo :=
                  'host='    || quote_literal(db_host)
               || ' port='    || quote_literal(db_port::text)
               || ' user='    || quote_literal(admin_user)
               || ' password='|| quote_literal(admin_password)
               || ' dbname='  || quote_literal(dbname)
               || ' sslmode=' || quote_literal('require');

            ------------------------------------------------------------------
            -- (1) Index state: include parent table + index size (relation size)
            ------------------------------------------------------------------
            INSERT INTO tmp_index_state (dbname, schema, index_name, index_type, table_name, size_bytes, size_pretty, relfilenode)
            SELECT dbname,
                   t.*
            FROM dblink(conninfo,
                $SQL$
                SELECT
                    n.nspname::text  AS schema,
                    c.relname::text  AS index_name,
                    am.amname::text  AS index_type,
                    ct.relname::text AS table_name,
                    pg_relation_size(c.oid) AS size_bytes,
                    pg_size_pretty(pg_relation_size(c.oid)) AS size_pretty,
                    c.relfilenode
                FROM pg_class c
                JOIN pg_namespace n ON n.oid = c.relnamespace
                JOIN pg_am am       ON am.oid = c.relam
                JOIN pg_index i     ON i.indexrelid = c.oid
                JOIN pg_class ct    ON ct.oid = i.indrelid
                WHERE c.relkind = 'i'
                  AND n.nspname NOT IN ('pg_catalog','information_schema','pg_toast')
                $SQL$
            ) AS t(schema text, index_name text, index_type text, table_name text, size_bytes bigint, size_pretty text, relfilenode oid);

            ------------------------------------------------------------------
            -- Ensure pgstattuple exists in a known schema for pgstatindex/pgstattuple calls
            ------------------------------------------------------------------
            BEGIN
                PERFORM dblink(conninfo, 'CREATE EXTENSION IF NOT EXISTS pgstattuple WITH SCHEMA "DBAdmin"');
            EXCEPTION WHEN OTHERS THEN
                NULL;
            END;

            ------------------------------------------------------------------
            -- (2) Fragmentation (schema-qualified pgstatindex for B-tree)
            ------------------------------------------------------------------
            BEGIN
                INSERT INTO tmp_index_diag (dbname, schema, index_name, leaf_fragmentation, avg_leaf_density)
                SELECT dbname,
                       t.*
                FROM dblink(conninfo,
                    $SQL$
                    SELECT
                        n.nspname::text  AS schema,
                        c.relname::text  AS index_name,
                        ("DBAdmin".pgstatindex(c.oid)).leaf_fragmentation::float8   AS leaf_fragmentation,
                        ("DBAdmin".pgstatindex(c.oid)).avg_leaf_density::float8     AS avg_leaf_density
                    FROM pg_class c
                    JOIN pg_namespace n ON n.oid = c.relnamespace
                    JOIN pg_am am       ON am.oid = c.relam
                    WHERE c.relkind = 'i'
                      AND am.amname = 'btree'
                      AND n.nspname NOT IN ('pg_catalog','information_schema','pg_toast')
                    $SQL$
                ) AS t(schema text, index_name text, leaf_fragmentation float8, avg_leaf_density float8);
            EXCEPTION WHEN OTHERS THEN
                -- Uncomment for debugging:
                -- RAISE NOTICE 'pgstatindex failed on %: %', dbname, SQLERRM;
                NULL;
            END;

            ------------------------------------------------------------------
            -- (3) Index usage stats (pg_stat_user_indexes)
            ------------------------------------------------------------------
            BEGIN
                INSERT INTO tmp_index_usage (dbname, schema, index_name, idx_scan, idx_tup_read, idx_tup_fetch, last_idx_scan)
                SELECT dbname,
                       t.*
                FROM dblink(conninfo,
                    $SQL$
                    SELECT
                        schemaname::text AS schema,
                        indexrelname::text AS index_name,
                        idx_scan::bigint,
                        idx_tup_read::bigint,
                        idx_tup_fetch::bigint,
                        last_idx_scan::timestamptz
                    FROM pg_stat_user_indexes
                    $SQL$
                ) AS t(schema text, index_name text, idx_scan bigint, idx_tup_read bigint, idx_tup_fetch bigint, last_idx_scan timestamptz);
            EXCEPTION WHEN OTHERS THEN
                -- Older versions may not have last_idx_scan; retry without it
                BEGIN
                    INSERT INTO tmp_index_usage (dbname, schema, index_name, idx_scan, idx_tup_read, idx_tup_fetch, last_idx_scan)
                    SELECT dbname,
                           t.*,
                           NULL::timestamptz
                    FROM dblink(conninfo,
                        $SQL$
                        SELECT
                            schemaname::text AS schema,
                            indexrelname::text AS index_name,
                            idx_scan::bigint,
                            idx_tup_read::bigint,
                            idx_tup_fetch::bigint
                        FROM pg_stat_user_indexes
                        $SQL$
                    ) AS t(schema text, index_name text, idx_scan bigint, idx_tup_read bigint, idx_tup_fetch bigint);
                EXCEPTION WHEN OTHERS THEN
                    NULL;
                END;
            END;

            ------------------------------------------------------------------
            -- (4) Table maintenance stats + sizes + counts (relid-based)
            ------------------------------------------------------------------
            BEGIN
                INSERT INTO tmp_table_maint (
                    dbname, schema, table_name,
                    last_vacuum, last_autovacuum, last_analyze, last_autoanalyze,
                    n_dead_tup, n_live_tup, n_mod_since_analyze,
                    table_total_bytes, table_table_bytes, table_indexes_bytes
                )
                SELECT dbname,
                       t.*
                FROM dblink(conninfo,
                    $SQL$
                    SELECT
                        schemaname::text            AS schema,
                        relname::text               AS table_name,
                        last_vacuum,
                        last_autovacuum,
                        last_analyze,
                        last_autoanalyze,
                        n_dead_tup,
                        n_live_tup,
                        n_mod_since_analyze,
                        pg_total_relation_size(relid)  AS table_total_bytes,
                        pg_relation_size(relid)        AS table_table_bytes,
                        pg_indexes_size(relid)         AS table_indexes_bytes
                    FROM pg_stat_all_tables
                    WHERE schemaname NOT IN ('pg_catalog','information_schema','pg_toast')
                    $SQL$
                ) AS t(
                    schema text, table_name text,
                    last_vacuum timestamptz, last_autovacuum timestamptz,
                    last_analyze timestamptz, last_autoanalyze timestamptz,
                    n_dead_tup bigint, n_live_tup bigint, n_mod_since_analyze bigint,
                    table_total_bytes bigint, table_table_bytes bigint, table_indexes_bytes bigint
                );
            EXCEPTION WHEN OTHERS THEN
                NULL;
            END;

            ------------------------------------------------------------------
            -- (5) Index bloat (free%) for larger indexes
            ------------------------------------------------------------------
            BEGIN
                INSERT INTO tmp_index_bloat (dbname, schema, index_name, idx_free_percent)
                SELECT dbname,
                       t.*
                FROM dblink(conninfo,
                    format($SQL$
                        SELECT
                            n.nspname::text  AS schema,
                            c.relname::text  AS index_name,
                            ("DBAdmin".pgstattuple(c.oid)).free_percent::float8 AS idx_free_percent
                        FROM pg_class c
                        JOIN pg_namespace n ON n.oid = c.relnamespace
                        WHERE c.relkind='i'
                          AND n.nspname NOT IN ('pg_catalog','information_schema','pg_toast')
                          AND pg_relation_size(c.oid) >= %s
                        $SQL$, min_index_bytes::text)
                ) AS t(schema text, index_name text, idx_free_percent float8);
            EXCEPTION WHEN OTHERS THEN
                NULL;
            END;

            ------------------------------------------------------------------
            -- (6) Table bloat (free%) for larger tables
            ------------------------------------------------------------------
            BEGIN
                INSERT INTO tmp_table_bloat (dbname, schema, table_name, tbl_free_percent)
                SELECT dbname,
                       t.*
                FROM dblink(conninfo,
                    format($SQL$
                        SELECT
                            n.nspname::text  AS schema,
                            c.relname::text  AS table_name,
                            ("DBAdmin".pgstattuple(c.oid)).free_percent::float8 AS tbl_free_percent
                        FROM pg_class c
                        JOIN pg_namespace n ON n.oid = c.relnamespace
                        WHERE c.relkind='r'
                          AND n.nspname NOT IN ('pg_catalog','information_schema','pg_toast')
                          AND pg_relation_size(c.oid) >= %s
                        $SQL$, min_table_bytes::text)
                ) AS t(schema text, table_name text, tbl_free_percent float8);
            EXCEPTION WHEN OTHERS THEN
                NULL;
            END;

        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Skipping DB % due to error: %', dbname, SQLERRM;
            CONTINUE;
        END;
    END LOOP;
END$$;

-- 2) Build a comparison + add usage/maint/bloat + Health Score
WITH log_all AS (
    SELECT
        run_id, dbname, target, action, started_at, finished_at, success, detail,
        regexp_replace(target, '^[^.]+\.', '') AS index_name,   -- schema.index -> index
        regexp_replace(target, '\..*$', '')    AS schema_name   -- schema.index -> schema
    FROM maintenance.stats_update_run_log
),
last_reindex AS (   -- Latest REINDEX per index (if any)
    SELECT DISTINCT ON (dbname, schema_name, index_name)
           dbname, schema_name, index_name,
           run_id AS reindex_run_id,
           success AS reindex_success,
           detail AS reindex_detail,
           finished_at AS reindex_time
    FROM log_all
    WHERE action = 'REINDEX'
    ORDER BY dbname, schema_name, index_name, run_id DESC
),
prev_candidate AS ( -- Latest CANDIDATE BEFORE that REINDEX (to parse "size=…")
    SELECT x.dbname, x.schema_name, x.index_name, x.run_id AS candidate_run_id, x.detail AS candidate_detail
    FROM (
        SELECT
            c.*,
            ROW_NUMBER() OVER (PARTITION BY c.dbname, c.schema_name, c.index_name
                               ORDER BY c.run_id DESC) AS rn
        FROM log_all c
        JOIN last_reindex r
          ON r.dbname = c.dbname
         AND r.schema_name = c.schema_name
         AND r.index_name = c.index_name
         AND c.action = 'REINDEX_CANDIDATE'
         AND c.run_id < r.reindex_run_id
    ) AS x
    WHERE x.rn = 1
),
parsed_candidate AS ( -- Parse "size=NN UNIT"
    SELECT
        dbname, schema_name, index_name,
        candidate_run_id,
        candidate_detail,
        (regexp_match(candidate_detail, 'size=([0-9\.]+)\s*([A-Za-z]+)'))[1]::numeric AS cand_size_num,
        (regexp_match(candidate_detail, 'size=([0-9\.]+)\s*([A-Za-z]+)'))[2]::text    AS cand_size_unit
    FROM prev_candidate
),
cand_bytes AS (
    SELECT
        dbname, schema_name, index_name, candidate_run_id, candidate_detail,
        CASE upper(cand_size_unit)
            WHEN 'B'    THEN cand_size_num
            WHEN 'BYTES'THEN cand_size_num
            WHEN 'KB'   THEN cand_size_num * 1024
            WHEN 'KIB'  THEN cand_size_num * 1024
            WHEN 'MB'   THEN cand_size_num * 1024 * 1024
            WHEN 'MIB'  THEN cand_size_num * 1024 * 1024
            WHEN 'GB'   THEN cand_size_num * 1024 * 1024 * 1024
            WHEN 'GIB'  THEN cand_size_num * 1024 * 1024 * 1024
            WHEN 'TB'   THEN cand_size_num * 1024 * 1024 * 1024 * 1024
            WHEN 'TIB'  THEN cand_size_num * 1024 * 1024 * 1024 * 1024
            ELSE NULL
        END::bigint AS candidate_size_bytes
    FROM parsed_candidate
),
joined AS (  -- Current + logs + fragmentation + usage + maintenance + bloat
    SELECT
        s.dbname,
        s.schema,
        s.index_name,
        s.index_type,
        s.table_name,
        s.size_bytes      AS size_now_bytes,
        pg_size_pretty(s.size_bytes) AS size_now_pretty,
        s.relfilenode,
        r.reindex_time,
        r.reindex_success,
        r.reindex_detail,
        c.candidate_size_bytes,
        c.candidate_detail,
        d.leaf_fragmentation,
        d.avg_leaf_density,
        u.idx_scan,
        u.idx_tup_read,
        u.idx_tup_fetch,
        u.last_idx_scan,
        tm.last_vacuum,
        tm.last_autovacuum,
        tm.last_analyze,
        tm.last_autoanalyze,
        tm.n_dead_tup,
        tm.n_live_tup,
        tm.n_mod_since_analyze,
        tm.table_total_bytes,
        tm.table_table_bytes,
        tm.table_indexes_bytes,
        ib.idx_free_percent,
        tb.tbl_free_percent
    FROM tmp_index_state s
    LEFT JOIN last_reindex r
      ON r.dbname = s.dbname
     AND r.schema_name = s.schema
     AND r.index_name = s.index_name
    LEFT JOIN cand_bytes c
      ON c.dbname = s.dbname
     AND c.schema_name = s.schema
     AND c.index_name = s.index_name
    LEFT JOIN tmp_index_diag d
      ON d.dbname = s.dbname
     AND d.schema = s.schema
     AND d.index_name = s.index_name
    LEFT JOIN tmp_index_usage u
      ON u.dbname = s.dbname
     AND u.schema = s.schema
     AND u.index_name = s.index_name
    LEFT JOIN tmp_table_maint tm
      ON tm.dbname = s.dbname
     AND tm.schema = s.schema
     AND tm.table_name = s.table_name
    LEFT JOIN tmp_index_bloat ib
      ON ib.dbname = s.dbname
     AND ib.schema  = s.schema
     AND ib.index_name = s.index_name
    LEFT JOIN tmp_table_bloat tb
      ON tb.dbname = s.dbname
     AND tb.schema  = s.schema
     AND tb.table_name = s.table_name
)
SELECT
    dbname,
    schema,
    index_name,
    index_type,
    table_name,
    size_now_pretty   AS current_size,
    size_now_bytes,
    candidate_size_bytes AS size_before_bytes,
    leaf_fragmentation,
    avg_leaf_density,
    idx_free_percent,
    tbl_free_percent,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch,
    last_idx_scan,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze,
    n_dead_tup,
    n_live_tup,
	ROUND(100.0 * n_dead_tup / NULLIF(n_live_tup, 0), 2) AS dead_tup_percent,
    -- Table size context
    pg_size_pretty(table_total_bytes)   AS table_total_pretty,
    pg_size_pretty(table_table_bytes)   AS table_heap_pretty,
    pg_size_pretty(table_indexes_bytes) AS table_indexes_pretty,

    -- Stats staleness (ratio of changed rows since analyze)
    CASE
      WHEN COALESCE(n_live_tup,0)=0 THEN 0.0
      ELSE LEAST( (n_mod_since_analyze::numeric / NULLIF(n_live_tup,0)), 1.0 )
    END AS stats_change_ratio,

    -- Age of last analyze in hours
    EXTRACT(EPOCH FROM (now() - COALESCE(last_analyze, last_autoanalyze))) / 3600.0 AS hrs_since_analyze,

    -- Health Score (0 good … 100 bad)
    -- AFTER (works: cast to numeric, then round to 1 decimal)
ROUND( (100 * (
      0.30 * LEAST(COALESCE(leaf_fragmentation,0)/100.0, 1.0) --structure
    + 0.30 * LEAST(COALESCE(idx_free_percent,0)/100.0, 1.0)  --index bloat
    + 0.10 * LEAST(COALESCE(tbl_free_percent,0)/100.0, 1.0)   --table bloat
    + 0.20 * LEAST( CASE
                      WHEN COALESCE(n_live_tup,0)=0 THEN 0
                      ELSE n_mod_since_analyze::numeric / NULLIF(n_live_tup,0)
                    END, 1.0)      ---stats staleness
    + 0.10 * (CASE
                WHEN size_now_bytes >= 1048576 AND COALESCE(idx_scan,0)=0 THEN 1.0
                WHEN COALESCE(idx_scan,0) < 10 THEN 0.5
                ELSE 0.0         --low usage penalty
              END)
  ))::numeric, 1) AS health_score,
    CASE
      WHEN reindex_success IS FALSE THEN 'FAIL: reindex error'
      WHEN reindex_success IS TRUE AND candidate_size_bytes IS NOT NULL AND size_now_bytes < candidate_size_bytes
           THEN 'PASS (size reduced)'
      WHEN reindex_success IS TRUE AND candidate_size_bytes IS NOT NULL AND size_now_bytes >= candidate_size_bytes
           THEN 'CHECK: size not reduced'
      WHEN reindex_success IS TRUE AND candidate_size_bytes IS NULL
           THEN 'OK (no baseline size parsed)'
      ELSE 'NO RECENT REINDEX LOG'
    END AS verification_status,

    relfilenode,
    reindex_time,
    reindex_detail,
    candidate_detail
FROM joined
-- Optional filters:
-- WHERE dbname = 'OneC_4681'
--   AND index_name = 'idx_stg_candidate_education_candidateid'
ORDER BY n_dead_tup DESC,dbname,  size_now_pretty DESC, leaf_fragmentation DESC,  index_name;