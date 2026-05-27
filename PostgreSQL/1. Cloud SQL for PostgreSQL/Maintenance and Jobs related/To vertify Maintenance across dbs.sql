-- Central, cross-database verification report (uses host/port/user/password)
-- Run this in the `postgres` database (the DB that hosts maintenance.stats_update_run_log)

-- 0) Ensure dblink
CREATE EXTENSION IF NOT EXISTS dblink;

-- 1) Collect current index state + fragmentation from ALL chosen DBs
DO $$
DECLARE
    -- >>>> EDIT these to match your environment
    db_host        TEXT := '10.75.156.3';
    db_port        INT  := 5432;
    admin_user     TEXT := 'postgres';
    admin_password TEXT := 'Gcpcloudadmin@2025';

    -- Scope of databases to scan
    include_dbs text[] := NULL;  -- e.g., ARRAY['db1','db2'] or NULL for all
    exclude_dbs text[] := ARRAY['postgres','template0','template1','cloudsqladmin'];  -- add more if needed

    dbname  text;
    conninfo text;
BEGIN
    -- Temp table: live index state (size + relfilenode)
    CREATE TEMP TABLE IF NOT EXISTS tmp_index_state (
        dbname          text,
        schema          text,
        index_name      text,
        index_type      text,
        size_bytes      bigint,
        size_pretty     text,
        relfilenode     oid
    ) ON COMMIT DROP;

    -- Temp table: fragmentation diagnostics (pgstatindex)
    CREATE TEMP TABLE IF NOT EXISTS tmp_index_diag (
        dbname              text,
        schema              text,
        index_name          text,
        leaf_fragmentation  double precision,
        avg_leaf_density    double precision
    ) ON COMMIT DROP;

    -- Clear if re-running
    TRUNCATE tmp_index_state;
    TRUNCATE tmp_index_diag;

    -- Loop all chosen DBs and pull index state
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

            -- Pull index state from the remote DB
            INSERT INTO tmp_index_state (dbname, schema, index_name, index_type, size_bytes, size_pretty, relfilenode)
            SELECT dbname,
                   t.*
            FROM dblink(conninfo,
                $SQL$
                SELECT
                    n.nspname::text  AS schema,
                    c.relname::text  AS index_name,
                    am.amname::text  AS index_type,
                    pg_relation_size(c.oid) AS size_bytes,
                    pg_size_pretty(pg_relation_size(c.oid)) AS size_pretty,
                    c.relfilenode
                FROM pg_class c
                JOIN pg_namespace n ON n.oid = c.relnamespace
                JOIN pg_am am       ON am.oid = c.relam
                WHERE c.relkind = 'i'
                  AND n.nspname NOT IN ('pg_catalog','information_schema','pg_toast')
                $SQL$
            ) AS t(schema text, index_name text, index_type text, size_bytes bigint, size_pretty text, relfilenode oid);

            -- Ensure pgstattuple exists in a known schema so pgstatindex() is callable/predictable
            BEGIN
                PERFORM dblink(conninfo, 'CREATE EXTENSION IF NOT EXISTS pgstattuple WITH SCHEMA "DBAdmin"');
            EXCEPTION WHEN OTHERS THEN
                -- ignore; we'll still try pgstatindex below
                NULL;
            END;

            -- Pull leaf_fragmentation and avg_leaf_density (schema-qualified)
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
                -- For troubleshooting, temporarily print the error:
                -- RAISE NOTICE 'pgstatindex failed on %: %', dbname, SQLERRM;
                NULL;
            END;

        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Skipping DB % due to error: %', dbname, SQLERRM;
            CONTINUE;
        END;
    END LOOP;
END$$;

-- 2) Build a comparison between "current state" and the central log
WITH log_all AS (
    SELECT
        run_id, dbname, target, action, started_at, finished_at, success, detail,
        regexp_replace(target, '^[^.]+\.', '') AS index_name,   -- schema.index -> index
        regexp_replace(target, '\..*$', '')    AS schema_name   -- schema.index -> schema
    FROM maintenance.stats_update_run_log
),
-- Latest REINDEX per index (if any)
last_reindex AS (
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
-- The latest CANDIDATE BEFORE that REINDEX (to parse "size=…")
prev_candidate AS (
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
-- Parse candidate "size=NN UNIT" into bytes (optional, relies on log message format)
parsed_candidate AS (
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
-- Join everything together with the current live state + fragmentation metrics
joined AS (
    SELECT
        s.dbname,
        s.schema,
        s.index_name,
        s.index_type,
        s.size_bytes      AS size_now_bytes,
        pg_size_pretty(s.size_bytes) AS size_now_pretty,
        s.relfilenode,
        r.reindex_time,
        r.reindex_success,
        r.reindex_detail,
        c.candidate_size_bytes,
        c.candidate_detail,
        d.leaf_fragmentation,
        d.avg_leaf_density
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
)
SELECT
    dbname,
    schema,
    index_name,
    index_type,
    size_now_pretty   AS current_size,
    size_now_bytes,
    candidate_size_bytes AS size_before_bytes,
    leaf_fragmentation,
    avg_leaf_density,
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
FROM joined where dbname='OneC_4681' --and index_name='idx_stg_candidate_education_candidateid'
ORDER BY schema, size_now_pretty DESC, leaf_fragmentation desc, index_name;