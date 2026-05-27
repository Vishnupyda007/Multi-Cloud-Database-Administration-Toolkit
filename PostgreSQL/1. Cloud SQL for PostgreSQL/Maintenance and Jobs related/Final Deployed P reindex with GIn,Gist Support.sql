-- 0) Safety: create schema and run-log table if missing
CREATE SCHEMA IF NOT EXISTS maintenance;

-- Minimal run-log table (idempotent)
CREATE TABLE IF NOT EXISTS maintenance.stats_update_run_log
(
    run_id bigint NOT NULL,
    run_ts timestamp with time zone NOT NULL DEFAULT now(),
    dbname text COLLATE pg_catalog."default" NOT NULL,
    target text COLLATE pg_catalog."default" NOT NULL,
    action text COLLATE pg_catalog."default" NOT NULL,
    started_at timestamp with time zone NOT NULL,
    finished_at timestamp with time zone NOT NULL,
    success boolean NOT NULL,
    detail text COLLATE pg_catalog."default",
    CONSTRAINT stats_update_run_log_pkey PRIMARY KEY (run_id)
)

TABLESPACE pg_default;





-- 1) Create the sequence (idempotent)
CREATE SEQUENCE IF NOT EXISTS maintenance.stats_update_run_log_run_id_seq
    INCREMENT BY 1
    START WITH 1
    MINVALUE 1
    NO MAXVALUE
    CACHE 1;

-- 2) Make the sequence "owned by" the column so it drops automatically with the column
ALTER SEQUENCE maintenance.stats_update_run_log_run_id_seq
    OWNED BY maintenance.stats_update_run_log.run_id;

-- 3) Set the column default to use the sequence
ALTER TABLE maintenance.stats_update_run_log
    ALTER COLUMN run_id SET DEFAULT nextval('maintenance.stats_update_run_log_run_id_seq');

-- 4) (Important) If the table already has rows, advance the sequence so it won’t collide--not required
--SELECT setval(
 --   'maintenance.stats_update_run_log_run_id_seq',
 --   COALESCE((SELECT MAX(run_id) FROM maintenance.stats_update_run_log), 0)
--);



CREATE INDEX IF NOT EXISTS ix_stats_update_run_log_started_at
    ON maintenance.stats_update_run_log (started_at DESC);

-- 1) Ensure dblink is available in the current DB
CREATE EXTENSION IF NOT EXISTS dblink;

-- 2) Create/replace the procedure (B-tree bloat OR fragmentation → reindex)
CREATE OR REPLACE PROCEDURE maintenance.usp_reindex_bloated_indexes_proc(
    p_host text,
    p_port integer,
    p_dbname text,                  -- meta DB to enumerate pg_database (e.g., 'postgres')
    p_user text,
    p_password text,
    p_include_dbs text[] DEFAULT NULL,                                    -- only these DBs
    p_exclude_dbs text[] DEFAULT ARRAY['postgres','template0','template1','cloudsqladmin'],
    p_schema_filter text DEFAULT NULL,                                    -- e.g., 'public'
    p_index_name_like text DEFAULT NULL,                                  -- e.g., '%cust%'
    p_bloat_threshold_pct numeric DEFAULT 40,                             -- threshold for free_percent (pgstattuple)
    p_use_pgstattuple boolean DEFAULT false,                              -- precise mode (B-tree bloat)
    p_dry_run boolean DEFAULT true,                                       -- log only
    p_statement_timeout_ms integer DEFAULT 0,                             -- 0=no timeout
    p_always_include_pk boolean DEFAULT true,                             -- always include PK indexes
    p_min_index_size_bytes bigint DEFAULT 1048576,                        -- skip tiny indexes (<1 MiB) unless set to 0
    p_use_pgstatindex boolean DEFAULT true,                               -- consider B-tree fragmentation (leaf_fragmentation)
    p_fragmentation_threshold_pct numeric DEFAULT 30                      -- threshold for leaf_fragmentation (pgstatindex)
)
LANGUAGE plpgsql
AS $proc$
DECLARE
    base_conn_str text;
    meta_conn_str text;
    sql_list_dbs  text;
    db_row        record;
    conn_name     text;
    v_sqlstate    text;
    v_msg         text;

    -- preflight
    v_user_exists boolean;
    v_can_connect boolean;
    v_has_maintain boolean;
    v_detail      text;

    -- dynamic SQL text holders
    sql_candidates_est      text;   -- generic estimator (any AM, approximate)
    sql_candidates_btree_pf text;   -- B-tree precise: pgstattuple + pgstatindex
    sql_candidates_gin_pi   text;   -- GIN via pageinspect
    sql_candidates_gist_spg text;   -- GiST / SP-GiST via estimator
    sql_candidates_hash     text;   -- Hash via estimator
    sql_candidates_brin     text;   -- BRIN list for summarization
    sql_pk_btree            text;   -- non-partitioned PK (physical)
    sql_pk_children         text;   -- child PK indexes for partitioned parents

    -- row holder
    r_idx record;
BEGIN
    ----------------------------------------------------------------------
    -- Force IST for this session in log records
    ----------------------------------------------------------------------
    PERFORM set_config('TimeZone', 'Asia/Kolkata', true);

    -- dblink conninfos (SSL required on Cloud SQL / managed)
    base_conn_str := format(
        'host=%L port=%L user=%L password=%L sslmode=require connect_timeout=5',
        p_host, p_port::text, p_user, p_password
    );
    meta_conn_str := base_conn_str || format(' dbname=%L', p_dbname);

    -- Enumerate user databases
    sql_list_dbs := $Q$
        SELECT datname
        FROM pg_database
        WHERE datallowconn
          AND NOT datistemplate
        ORDER BY datname
    $Q$;

    -- Sanity dblink test
    BEGIN
        PERFORM 1 FROM dblink(meta_conn_str, 'SELECT 1') AS t(x int);
    EXCEPTION WHEN others THEN
        GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
        INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
        VALUES (p_dbname, p_dbname, 'CONNECT', now(), now(), false,
                format('meta dblink test failed: sqlstate=%s message=%s', v_sqlstate, v_msg));
        RETURN;
    END;

    ----------------------------------------------------------------------
    -- PREFLIGHT: cluster-wide role membership (pg_maintain) + user
    ----------------------------------------------------------------------
    BEGIN
        SELECT user_exists, has_maintain INTO v_user_exists, v_has_maintain
        FROM dblink(meta_conn_str,
            format(
                $Q$SELECT
                    EXISTS (SELECT 1 FROM pg_roles WHERE rolname=%L) AS user_exists,
                    EXISTS (
                        SELECT 1
                        FROM pg_roles u
                        JOIN pg_auth_members m ON m.member=u.oid
                        JOIN pg_roles r ON r.oid=m.roleid
                        WHERE u.rolname=%L AND r.rolname IN ('pg_maintain')
                    ) AS has_maintain$Q$,
                p_user, p_user
            )
        ) AS t(user_exists boolean, has_maintain boolean);

        v_detail := format('preflight role: user_exists=%s has_pg_maintain=%s', v_user_exists, v_has_maintain);
        INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
        VALUES (p_dbname, '-', 'PREFLIGHT_ROLE_REINDEX', now(), now(), (v_user_exists AND v_has_maintain), v_detail);
    EXCEPTION WHEN others THEN
        GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
        INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
        VALUES (p_dbname, '-', 'PREFLIGHT_ROLE_REINDEX', now(), now(), false,
                format('preflight role check failed: sqlstate=%s message=%s', v_sqlstate, v_msg));
    END;

    ----------------------------------------------------------------------
    -- PREFLIGHT: per-database CONNECT privilege
    ----------------------------------------------------------------------
    FOR db_row IN
        SELECT datname
        FROM dblink(meta_conn_str, sql_list_dbs) AS t(datname text)
        WHERE (p_include_dbs IS NULL OR datname = ANY(p_include_dbs))
          AND (p_exclude_dbs IS NULL OR NOT (datname = ANY(p_exclude_dbs)))
    LOOP
        BEGIN
            SELECT user_exists, can_connect INTO v_user_exists, v_can_connect
            FROM dblink(meta_conn_str,
                format(
                    $Q$SELECT
                        EXISTS (SELECT 1 FROM pg_roles WHERE rolname = %L) AS user_exists,
                        has_database_privilege(%L, %L, 'CONNECT') AS can_connect$Q$,
                    p_user, p_user, db_row.datname
                )
            ) AS t(user_exists boolean, can_connect boolean);

            v_detail := format('preflight db=%s user_exists=%s can_connect=%s has_pg_maintain=%s',
                               db_row.datname, v_user_exists, v_can_connect, v_has_maintain);
            INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
            VALUES (db_row.datname, db_row.datname, 'PREFLIGHT_REINDEX', now(), now(),
                    (v_user_exists AND v_can_connect), v_detail);
        EXCEPTION WHEN others THEN
            GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
            INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
            VALUES (db_row.datname, db_row.datname, 'PREFLIGHT_REINDEX', now(), now(), false,
                    format('preflight db=%s failed: sqlstate=%s message=%s', db_row.datname, v_sqlstate, v_msg));
        END;
    END LOOP;

    ----------------------------------------------------------------------
    -- Candidate SQL (Estimator — generic, safe for any AM)
    ----------------------------------------------------------------------
    sql_candidates_est := $EST$
        WITH idx AS (
            SELECT i.indexrelid AS idx_oid,
                   i.indrelid    AS tbl_oid,
                   n.nspname     AS schema,
                   c2.relname    AS index_name,
                   c.relname     AS table_name,
                   c2.relpages   AS ipages,
                   c2.reltuples  AS ituples,
                   am.amname     AS amname
            FROM pg_index i
            JOIN pg_class      c  ON c.oid  = i.indrelid
            JOIN pg_class      c2 ON c2.oid = i.indexrelid
            JOIN pg_namespace  n  ON n.oid  = c.relnamespace
            JOIN pg_am         am ON am.oid = c2.relam
            WHERE c.relkind IN ('r','p')
              AND c2.relkind = 'i'
              AND n.nspname NOT IN ('pg_catalog','information_schema','pg_toast')
        ),
        est AS (
            SELECT schema, table_name, index_name, amname,
                   ipages, ituples,
                   GREATEST(1, CEIL(NULLIF(ituples,0)))::bigint AS iotta
            FROM idx
        )
        SELECT schema, table_name, index_name, amname,
               CASE
                 WHEN iotta = 0 OR ipages = 0 THEN 0
                 ELSE ROUND(100.0 * GREATEST(ipages - iotta, 0)::numeric / NULLIF(ipages,0), 2)
               END AS bloat_pct,
               pg_relation_size(format('%I.%I', schema, index_name)) AS idx_bytes
        FROM est
    $EST$;

    ----------------------------------------------------------------------
    -- Candidate SQL (B-tree precise) — pgstattuple + pgstatindex
    ----------------------------------------------------------------------
    sql_candidates_btree_pf := $BTPF$
        SELECT
          n.nspname AS schema,
          c.relname AS index_name,
          ct.relname AS table_name,
          (st).free_percent::numeric(10,2)        AS free_pct,
          (si).leaf_fragmentation::numeric(10,2)  AS frag_pct,
          pg_relation_size(c.oid)                 AS idx_bytes
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        JOIN pg_index i      ON i.indexrelid = c.oid
        JOIN pg_class ct     ON ct.oid = i.indrelid
        JOIN pg_am am        ON am.oid   = c.relam
        CROSS JOIN LATERAL "DBAdmin".pgstattuple(c.oid::regclass) AS st
        CROSS JOIN LATERAL "DBAdmin".pgstatindex(c.oid::regclass) AS si
        WHERE c.relkind='i'
          AND am.amname='btree'
          AND n.nspname NOT IN ('pg_catalog','information_schema','pg_toast')
    $BTPF$;

    ----------------------------------------------------------------------
    -- Candidate SQL (GIN via pageinspect; superuser-only functions)
    ----------------------------------------------------------------------
    sql_candidates_gin_pi := $GINPI$
        SELECT schema, index_name, table_name,
               n_pending_pages, n_pending_tuples,
               n_total_pages, n_entry_pages, n_data_pages, n_entries,
               idx_bytes, pending_ratio_pct
        FROM (
            SELECT n.nspname AS schema,
                   c.relname  AS index_name,
                   ct.relname AS table_name,
                   mi.pending_head, mi.pending_tail, mi.tail_free_size,
                   mi.n_pending_pages, mi.n_pending_tuples,
                   mi.n_total_pages, mi.n_entry_pages, mi.n_data_pages, mi.n_entries, mi.version,
                   pg_relation_size(c.oid) AS idx_bytes,
                   CASE WHEN mi.n_total_pages > 0
                        THEN ROUND(100.0 * mi.n_pending_pages::numeric / mi.n_total_pages, 2)
                        ELSE 0 END AS pending_ratio_pct
            FROM pg_class c
            JOIN pg_index i  ON i.indexrelid = c.oid
            JOIN pg_class ct ON ct.oid = i.indrelid
            JOIN pg_namespace n ON n.oid = c.relnamespace
            JOIN pg_am am ON am.oid = c.relam
            CROSS JOIN LATERAL pageinspect.gin_metapage_info(
                pageinspect.get_raw_page(format('%I.%I', n.nspname, c.relname), 0)
            ) AS mi
            WHERE c.relkind='i'
              AND am.amname='gin'
              AND n.nspname NOT IN ('pg_catalog','information_schema','pg_toast')
        ) s
    $GINPI$;

    ----------------------------------------------------------------------
    -- Candidate SQL (GiST / SP-GiST via estimator)
    ----------------------------------------------------------------------
    sql_candidates_gist_spg := $GSPG$
        WITH idx AS (
            SELECT i.indexrelid AS idx_oid,
                   i.indrelid    AS tbl_oid,
                   n.nspname     AS schema,
                   c2.relname    AS index_name,
                   c.relname     AS table_name,
                   c2.relpages   AS ipages,
                   c2.reltuples  AS ituples,
                   am.amname     AS amname
            FROM pg_index i
            JOIN pg_class      c  ON c.oid  = i.indrelid
            JOIN pg_class      c2 ON c2.oid = i.indexrelid
            JOIN pg_namespace  n  ON n.oid  = c.relnamespace
            JOIN pg_am         am ON am.oid = c2.relam
            WHERE c.relkind IN ('r','p')
              AND c2.relkind = 'i'
              AND am.amname IN ('gist','spgist')
              AND n.nspname NOT IN ('pg_catalog','information_schema','pg_toast')
        ),
        est AS (
            SELECT schema, table_name, index_name, amname,
                   ipages, ituples,
                   GREATEST(1, CEIL(NULLIF(ituples,0)))::bigint AS iotta
            FROM idx
        )
        SELECT schema, table_name, index_name, amname,
               CASE
                 WHEN iotta = 0 OR ipages = 0 THEN 0
                 ELSE ROUND(100.0 * GREATEST(ipages - iotta, 0)::numeric / NULLIF(ipages,0), 2)
               END AS bloat_pct,
               pg_relation_size(format('%I.%I', schema, index_name)) AS idx_bytes
        FROM est
    $GSPG$;

    ----------------------------------------------------------------------
    -- Candidate SQL (Hash via estimator)
    ----------------------------------------------------------------------
    sql_candidates_hash := $HSH$
        WITH idx AS (
            SELECT i.indexrelid AS idx_oid,
                   i.indrelid    AS tbl_oid,
                   n.nspname     AS schema,
                   c2.relname    AS index_name,
                   c.relname     AS table_name,
                   c2.relpages   AS ipages,
                   c2.reltuples  AS ituples,
                   am.amname     AS amname
            FROM pg_index i
            JOIN pg_class      c  ON c.oid  = i.indrelid
            JOIN pg_class      c2 ON c2.oid = i.indexrelid
            JOIN pg_namespace  n  ON n.oid  = c.relnamespace
            JOIN pg_am         am ON am.oid = c2.relam
            WHERE c.relkind IN ('r','p')
              AND c2.relkind = 'i'
              AND am.amname = 'hash'
              AND n.nspname NOT IN ('pg_catalog','information_schema','pg_toast')
        ),
        est AS (
            SELECT schema, table_name, index_name, amname,
                   ipages, ituples,
                   GREATEST(1, CEIL(NULLIF(ituples,0)))::bigint AS iotta
            FROM idx
        )
        SELECT schema, table_name, index_name, amname,
               CASE
                 WHEN iotta = 0 OR ipages = 0 THEN 0
                 ELSE ROUND(100.0 * GREATEST(ipages - iotta, 0)::numeric / NULLIF(ipages,0), 2)
               END AS bloat_pct,
               pg_relation_size(format('%I.%I', schema, index_name)) AS idx_bytes
        FROM est
    $HSH$;

    ----------------------------------------------------------------------
    -- Candidate SQL (BRIN list for summarization)
    ----------------------------------------------------------------------
    sql_candidates_brin := $BRIN$
        SELECT n.nspname AS schema,
               c.relname AS index_name,
               ct.relname AS table_name,
               pg_relation_size(c.oid) AS idx_bytes
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        JOIN pg_index i ON i.indexrelid = c.oid
        JOIN pg_class ct ON ct.oid = i.indrelid
        JOIN pg_am am ON am.oid = c.relam
        WHERE c.relkind='i'
          AND am.amname='brin'
          AND n.nspname NOT IN ('pg_catalog','information_schema','pg_toast')
    $BRIN$;

    ----------------------------------------------------------------------
    -- PRIMARY KEY discovery SQL
    ----------------------------------------------------------------------
    -- Non-partitioned PRIMARY KEY B-tree indexes (physical, relkind='i')
    sql_pk_btree := $PKI$
        SELECT n.nspname AS schema,
               i.relname AS index_name,
               t.relname AS table_name,
               pg_relation_size(i.oid) AS idx_bytes
        FROM pg_constraint c
        JOIN pg_class     i ON i.oid = c.conindid
        JOIN pg_namespace n ON n.oid = i.relnamespace
        JOIN pg_index     x ON x.indexrelid = i.oid
        JOIN pg_class     t ON t.oid = x.indrelid
        JOIN pg_am        am ON am.oid = i.relam
        WHERE c.contype = 'p'
          AND am.amname = 'btree'
          AND i.relkind = 'i'    -- physical index
          AND n.nspname NOT IN ('pg_catalog','information_schema','pg_toast')
    $PKI$;

    -- Child (physical) indexes for partitioned PRIMARY KEYs (parent relkind='I')
    sql_pk_children := $PKC$
        SELECT nc.nspname AS schema,
               ic.relname AS index_name,
               tt.relname AS table_name,
               pg_relation_size(ic.oid) AS idx_bytes
        FROM pg_constraint c
        JOIN pg_class       pi ON pi.oid = c.conindid                 -- parent partitioned index
        JOIN pg_namespace   pn ON pn.oid = pi.relnamespace
        JOIN pg_inherits    inh ON inh.inhparent = c.conindid         -- child indexes
        JOIN pg_class       ic ON ic.oid = inh.inhrelid               -- child index rel
        JOIN pg_namespace   nc ON nc.oid = ic.relnamespace
        JOIN pg_index       ix ON ix.indexrelid = ic.oid
        JOIN pg_class       tt ON tt.oid = ix.indrelid                -- child table
        JOIN pg_am          am ON am.oid = ic.relam
        WHERE c.contype = 'p'
          AND pi.relkind = 'I'     -- parent is a partitioned index
          AND am.amname = 'btree'
          AND nc.nspname NOT IN ('pg_catalog','information_schema','pg_toast')
    $PKC$;

    ----------------------------------------------------------------------
    -- MAIN LOOP
    ----------------------------------------------------------------------
    FOR db_row IN
        SELECT datname
        FROM dblink(meta_conn_str, sql_list_dbs) AS t(datname text)
        WHERE (p_include_dbs IS NULL OR datname = ANY(p_include_dbs))
          AND (p_exclude_dbs IS NULL OR NOT (datname = ANY(p_exclude_dbs)))
    LOOP
        conn_name := format('reindex_%s_%s', db_row.datname, md5(random()::text));

        -- connect
        BEGIN
            PERFORM dblink_connect(conn_name, base_conn_str || format(' dbname=%L', db_row.datname));
            PERFORM dblink_exec(conn_name, 'SET TIME ZONE ''Asia/Kolkata''' ); -- remote IST
            IF p_statement_timeout_ms > 0 THEN
                PERFORM dblink_exec(conn_name, format('SET statement_timeout=%s', p_statement_timeout_ms));
            END IF;
        EXCEPTION WHEN others THEN
            GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
            INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
            VALUES (db_row.datname, db_row.datname, 'CONNECT', now(), now(), false,
                    format('connect failed: sqlstate=%s message=%s', v_sqlstate, v_msg));
            CONTINUE;
        END;

        ------------------------------------------------------------------
        -- 1) B-tree precise (pgstattuple and/or pgstatindex)
        ------------------------------------------------------------------
        IF p_use_pgstattuple OR p_use_pgstatindex THEN
          BEGIN
            PERFORM dblink_exec(conn_name, 'CREATE EXTENSION IF NOT EXISTS pgstattuple WITH SCHEMA "DBAdmin"');
          EXCEPTION WHEN others THEN
            GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
            INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
            VALUES (db_row.datname, '-', 'REINDEX_CANDIDATES', now(), now(), false,
                    format('pgstattuple/pgstatindex not available: sqlstate=%s message=%s; using estimator', v_sqlstate, v_msg));
            p_use_pgstattuple := false;
            p_use_pgstatindex := false;
          END;
        END IF;

        IF p_use_pgstattuple OR p_use_pgstatindex THEN
          FOR r_idx IN
            SELECT * FROM dblink(conn_name, sql_candidates_btree_pf)
            AS t(schema text, index_name text, table_name text, free_pct numeric, frag_pct numeric, idx_bytes bigint)
            WHERE (p_schema_filter IS NULL OR schema = p_schema_filter)
              AND (p_index_name_like IS NULL OR index_name ILIKE p_index_name_like)
              AND idx_bytes >= p_min_index_size_bytes
              AND (
                    (p_use_pgstattuple  AND free_pct >= p_bloat_threshold_pct)
                 OR (p_use_pgstatindex AND frag_pct >= p_fragmentation_threshold_pct)
                  )
            ORDER BY
              GREATEST( COALESCE(free_pct,0),  COALESCE(frag_pct,0) ) DESC,
              idx_bytes DESC
          LOOP
            INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
            VALUES (db_row.datname,
                    format('%s.%s', r_idx.schema, r_idx.index_name),
                    'REINDEX_CANDIDATE',
                    now(), now(), true,
                    format('am=btree mode=precise free_pct=%s%% frag_pct=%s%% size=%s',
                           to_char(r_idx.free_pct, 'FM999999990D00'),
                           to_char(r_idx.frag_pct, 'FM999999990D00'),
                           pg_size_pretty(r_idx.idx_bytes)));

            IF NOT p_dry_run THEN
              BEGIN
                PERFORM dblink_exec(conn_name,
                    format('REINDEX INDEX CONCURRENTLY %I.%I', r_idx.schema, r_idx.index_name));
                INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
                VALUES (db_row.datname,
                        format('%s.%s', r_idx.schema, r_idx.index_name),
                        'REINDEX',
                        now(), now(), true,
                        format('reindexed concurrently (btree; free=%s%% frag=%s%%)',
                               to_char(r_idx.free_pct, 'FM999999990D00'),
                               to_char(r_idx.frag_pct, 'FM999999990D00')));
              EXCEPTION WHEN others THEN
                GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
                INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
                VALUES (db_row.datname,
                        format('%s.%s', r_idx.schema, r_idx.index_name),
                        'REINDEX',
                        now(), now(), false,
                        format('reindex failed: sqlstate=%s message=%s', v_sqlstate, v_msg));
              END;
            END IF;
          END LOOP;
        END IF;

        ------------------------------------------------------------------
        -- 2) GIN via pageinspect (superuser-only): pending ratio threshold
        ------------------------------------------------------------------
        BEGIN
            PERFORM dblink_exec(conn_name, 'CREATE EXTENSION IF NOT EXISTS pageinspect');
            FOR r_idx IN
                SELECT * FROM dblink(conn_name, sql_candidates_gin_pi)
                AS t(schema text, index_name text, table_name text,
                     n_pending_pages bigint, n_pending_tuples bigint,
                     n_total_pages bigint, n_entry_pages bigint, n_data_pages bigint, n_entries bigint,
                     idx_bytes bigint, pending_ratio_pct numeric)
                WHERE (p_schema_filter IS NULL OR schema = p_schema_filter)
                  AND (p_index_name_like IS NULL OR index_name ILIKE p_index_name_like)
                  AND pending_ratio_pct >= p_bloat_threshold_pct
                  AND idx_bytes >= p_min_index_size_bytes
                ORDER BY pending_ratio_pct DESC, idx_bytes DESC
            LOOP
                -- Log candidate
                INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
                VALUES (db_row.datname,
                        format('%s.%s', r_idx.schema, r_idx.index_name),
                        'REINDEX_CANDIDATE',
                        now(), now(), true,
                        format('am=gin mode=pageinspect pending_ratio_pct=%s%% size=%s pending_pages=%s total_pages=%s entries=%s',
                               to_char(r_idx.pending_ratio_pct::numeric, 'FM999999990D00'),
                               pg_size_pretty(r_idx.idx_bytes),
                               r_idx.n_pending_pages::text,
                               r_idx.n_total_pages::text,
                               r_idx.n_entries::text));

                IF NOT p_dry_run THEN
                    BEGIN
                        -- Optional: try to clean pending list first
                        BEGIN
                            PERFORM dblink_exec(conn_name,
                               format($X$SELECT gin_clean_pending_list('%I.%I'::regclass)$X$, r_idx.schema, r_idx.index_name));
                        EXCEPTION WHEN others THEN
                            NULL; -- ignore; proceed to reindex
                        END;

                        PERFORM dblink_exec(conn_name,
                            format('REINDEX INDEX CONCURRENTLY %I.%I', r_idx.schema, r_idx.index_name));

                        INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
                        VALUES (db_row.datname,
                                format('%s.%s', r_idx.schema, r_idx.index_name),
                                'REINDEX',
                                now(), now(), true,
                                format('reindexed concurrently (gin, pending_ratio_pct=%s%%)',
                                       to_char(r_idx.pending_ratio_pct::numeric, 'FM999999990D00')));
                    EXCEPTION WHEN others THEN
                        GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
                        INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
                        VALUES (db_row.datname,
                                format('%s.%s', r_idx.schema, r_idx.index_name),
                                'REINDEX',
                                now(), now(), false,
                                format('reindex failed: sqlstate=%s message=%s', v_sqlstate, v_msg));
                    END;
                END IF;
            END LOOP;
        EXCEPTION WHEN others THEN
            GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
            INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
            VALUES (db_row.datname, '-', 'GIN_PAGEINSPECT', now(), now(), false,
                    format('pageinspect path skipped: sqlstate=%s message=%s', v_sqlstate, v_msg));
        END;

        ------------------------------------------------------------------
        -- 2b) GiST / SP-GiST via estimator
        ------------------------------------------------------------------
        FOR r_idx IN
            SELECT * FROM dblink(conn_name, sql_candidates_gist_spg)
            AS t(schema text, table_name text, index_name text, amname text, bloat_pct numeric, idx_bytes bigint)
            WHERE (p_schema_filter IS NULL OR schema = p_schema_filter)
              AND (p_index_name_like IS NULL OR index_name ILIKE p_index_name_like)
              AND bloat_pct >= p_bloat_threshold_pct
              AND idx_bytes >= p_min_index_size_bytes
            ORDER BY bloat_pct DESC, idx_bytes DESC
        LOOP
            INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
            VALUES (db_row.datname,
                    format('%s.%s', r_idx.schema, r_idx.index_name),
                    'REINDEX_CANDIDATE',
                    now(), now(), true,
                    format('am=%s mode=estimator bloat_pct=%s size=%s',
                           r_idx.amname,
                           to_char(r_idx.bloat_pct::numeric, 'FM999999990D00'),
                           pg_size_pretty(r_idx.idx_bytes)));

            IF NOT p_dry_run THEN
                BEGIN
                    PERFORM dblink_exec(conn_name,
                        format('REINDEX INDEX CONCURRENTLY %I.%I', r_idx.schema, r_idx.index_name));
                    INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
                    VALUES (db_row.datname,
                            format('%s.%s', r_idx.schema, r_idx.index_name),
                            'REINDEX',
                            now(), now(), true,
                            format('reindexed concurrently (%s, estimator %s%%)',
                                   r_idx.amname,
                                   to_char(r_idx.bloat_pct::numeric, 'FM999999990D00')));
                EXCEPTION WHEN others THEN
                    GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
                    INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
                    VALUES (db_row.datname,
                            format('%s.%s', r_idx.schema, r_idx.index_name),
                            'REINDEX',
                            now(), now(), false,
                            format('reindex failed: sqlstate=%s message=%s', v_sqlstate, v_msg));
                END;
            END IF;
        END LOOP;

        ------------------------------------------------------------------
        -- 2c) Hash via estimator
        ------------------------------------------------------------------
        FOR r_idx IN
            SELECT * FROM dblink(conn_name, sql_candidates_hash)
            AS t(schema text, table_name text, index_name text, amname text, bloat_pct numeric, idx_bytes bigint)
            WHERE (p_schema_filter IS NULL OR schema = p_schema_filter)
              AND (p_index_name_like IS NULL OR index_name ILIKE p_index_name_like)
              AND bloat_pct >= p_bloat_threshold_pct
              AND idx_bytes >= p_min_index_size_bytes
            ORDER BY bloat_pct DESC, idx_bytes DESC
        LOOP
            INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
            VALUES (db_row.datname,
                    format('%s.%s', r_idx.schema, r_idx.index_name),
                    'REINDEX_CANDIDATE',
                    now(), now(), true,
                    format('am=%s mode=estimator bloat_pct=%s size=%s',
                           r_idx.amname,
                           to_char(r_idx.bloat_pct::numeric, 'FM999999990D00'),
                           pg_size_pretty(r_idx.idx_bytes)));

            IF NOT p_dry_run THEN
                BEGIN
                    PERFORM dblink_exec(conn_name,
                        format('REINDEX INDEX CONCURRENTLY %I.%I', r_idx.schema, r_idx.index_name));
                    INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
                    VALUES (db_row.datname,
                            format('%s.%s', r_idx.schema, r_idx.index_name),
                            'REINDEX',
                            now(), now(), true,
                            format('reindexed concurrently (%s, estimator %s%%)',
                                   r_idx.amname,
                                   to_char(r_idx.bloat_pct::numeric, 'FM999999990D00')));
                EXCEPTION WHEN others THEN
                    GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
                    INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
                    VALUES (db_row.datname,
                            format('%s.%s', r_idx.schema, r_idx.index_name),
                            'REINDEX',
                            now(), now(), false,
                            format('reindex failed: sqlstate=%s message=%s', v_sqlstate, v_msg));
                END;
            END IF;
        END LOOP;

        ------------------------------------------------------------------
        -- 2d) BRIN maintenance: summarize new values
        ------------------------------------------------------------------
        FOR r_idx IN
            SELECT * FROM dblink(conn_name, sql_candidates_brin)
            AS t(schema text, index_name text, table_name text, idx_bytes bigint)
            WHERE (p_schema_filter IS NULL OR schema = p_schema_filter)
              AND (p_index_name_like IS NULL OR index_name ILIKE p_index_name_like)
        LOOP
            BEGIN
                PERFORM dblink_exec(conn_name,
                    format($B$SELECT brin_summarize_new_values('%I.%I'::regclass)$B$, r_idx.schema, r_idx.index_name));

                INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
                VALUES (db_row.datname,
                        format('%s.%s', r_idx.schema, r_idx.index_name),
                        'BRIN_SUMMARIZE',
                        now(), now(), true,
                        format('attempted summarize_new_values; size=%s', pg_size_pretty(r_idx.idx_bytes)));
            EXCEPTION WHEN others THEN
                GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
                INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
                VALUES (db_row.datname,
                        format('%s.%s', r_idx.schema, r_idx.index_name),
                        'BRIN_SUMMARIZE',
                        now(), now(), false,
                        format('summarize failed: sqlstate=%s message=%s', v_sqlstate, v_msg));
            END;
        END LOOP;

        ------------------------------------------------------------------
        -- 2e) PRIMARY KEY (non-partitioned): always include if requested
        ------------------------------------------------------------------
        IF p_always_include_pk THEN
            FOR r_idx IN
                SELECT * FROM dblink(conn_name, sql_pk_btree)
                AS t(schema text, index_name text, table_name text, idx_bytes bigint)
                WHERE (p_schema_filter IS NULL OR schema = p_schema_filter)
                  AND (p_index_name_like IS NULL OR index_name ILIKE p_index_name_like)
            LOOP
                INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
                VALUES (db_row.datname,
                        format('%s.%s', r_idx.schema, r_idx.index_name),
                        'REINDEX_CANDIDATE',
                        now(), now(), true,
                        format('am=btree type=PRIMARY KEY size=%s', pg_size_pretty(r_idx.idx_bytes)));

                IF NOT p_dry_run THEN
                    BEGIN
                        PERFORM dblink_exec(conn_name,
                            format('REINDEX INDEX CONCURRENTLY %I.%I', r_idx.schema, r_idx.index_name));
                        INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
                        VALUES (db_row.datname,
                                format('%s.%s', r_idx.schema, r_idx.index_name),
                                'REINDEX',
                                now(), now(), true,
                                'reindexed concurrently (PRIMARY KEY)');
                    EXCEPTION WHEN others THEN
                        GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
                        INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
                        VALUES (db_row.datname,
                                format('%s.%s', r_idx.schema, r_idx.index_name),
                                'REINDEX',
                                now(), now(), false,
                                format('reindex failed (PK): sqlstate=%s message=%s', v_sqlstate, v_msg));
                    END;
                END IF;
            END LOOP;
        END IF;

        ------------------------------------------------------------------
        -- 2f) PRIMARY KEY on partitioned tables: reindex child PK indexes
        ------------------------------------------------------------------
        IF p_always_include_pk THEN
            FOR r_idx IN
                SELECT * FROM dblink(conn_name, sql_pk_children)
                AS t(schema text, index_name text, table_name text, idx_bytes bigint)
                WHERE (p_schema_filter IS NULL OR schema = p_schema_filter)
                  AND (p_index_name_like IS NULL OR index_name ILIKE p_index_name_like)
            LOOP
                INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
                VALUES (db_row.datname,
                        format('%s.%s', r_idx.schema, r_idx.index_name),
                        'REINDEX_CANDIDATE',
                        now(), now(), true,
                        format('am=btree type=PRIMARY KEY(partition-child) size=%s', pg_size_pretty(r_idx.idx_bytes)));

                IF NOT p_dry_run THEN
                    BEGIN
                        PERFORM dblink_exec(conn_name,
                            format('REINDEX INDEX CONCURRENTLY %I.%I', r_idx.schema, r_idx.index_name));
                        INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
                        VALUES (db_row.datname,
                                format('%s.%s', r_idx.schema, r_idx.index_name),
                                'REINDEX',
                                now(), now(), true,
                                'reindexed concurrently (PK child of partitioned table)');
                    EXCEPTION WHEN others THEN
                        GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
                        INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
                        VALUES (db_row.datname,
                                format('%s.%s', r_idx.schema, r_idx.index_name),
                                'REINDEX',
                                now(), now(), false,
                                format('reindex failed (PK child): sqlstate=%s message=%s', v_sqlstate, v_msg));
                    END;
                END IF;
            END LOOP;
        END IF;

        ------------------------------------------------------------------
        -- 3) Estimator path as a catch-all (when precise paths aren't used)
        ------------------------------------------------------------------
        IF NOT p_use_pgstattuple AND NOT p_use_pgstatindex THEN
            FOR r_idx IN
                SELECT * FROM dblink(conn_name, sql_candidates_est)
                AS t(schema text, table_name text, index_name text, amname text, bloat_pct numeric, idx_bytes bigint)
                WHERE (p_schema_filter IS NULL OR schema = p_schema_filter)
                  AND (p_index_name_like IS NULL OR index_name ILIKE p_index_name_like)
                  AND bloat_pct >= p_bloat_threshold_pct
                  AND idx_bytes >= p_min_index_size_bytes
                ORDER BY bloat_pct DESC, idx_bytes DESC
            LOOP
                INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
                VALUES (db_row.datname,
                        format('%s.%s', r_idx.schema, r_idx.index_name),
                        'REINDEX_CANDIDATE',
                        now(), now(), true,
                        format('am=%s mode=estimator bloat_pct=%s size=%s',
                               r_idx.amname,
                               to_char(r_idx.bloat_pct::numeric, 'FM999999990D00'),
                               pg_size_pretty(r_idx.idx_bytes)));

                IF NOT p_dry_run THEN
                    BEGIN
                        PERFORM dblink_exec(conn_name,
                            format('REINDEX INDEX CONCURRENTLY %I.%I', r_idx.schema, r_idx.index_name));
                        INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
                        VALUES (db_row.datname,
                                format('%s.%s', r_idx.schema, r_idx.index_name),
                                'REINDEX',
                                now(), now(), true,
                                format('reindexed concurrently (estimator %s%%)',
                                       to_char(r_idx.bloat_pct::numeric, 'FM999999990D00')));
                    EXCEPTION WHEN others THEN
                        GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
                        INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
                        VALUES (db_row.datname,
                                format('%s.%s', r_idx.schema, r_idx.index_name),
                                'REINDEX',
                                now(), now(), false,
                                format('reindex failed: sqlstate=%s message=%s', v_sqlstate, v_msg));
                    END;
                END IF;
            END LOOP;
        END IF;

        PERFORM dblink_disconnect(conn_name);
    END LOOP;
END;
$proc$;



GRANT EXECUTE ON PROCEDURE maintenance.usp_reindex_bloated_indexes_proc TO "DBMaintenanceUser";
GRANT pg_stat_scan_tables TO "DBMaintenanceUser";
grant pg_maintain to "DBMaintenanceUser";

--have access 
GRANT EXECUTE ON FUNCTION %1$I.pgstattuple(regclass) TO %2$I; grant usage on schema "DBAdmin" to "DBMaintenanceUser"; grant select,delete on table "DBAdmin".ddl_event_log to "DBMaintenanceUser";

---in postgres db, under maintenance:
grant all on table maintenance.stats_update_run_log to "DBMaintenanceUser";


-- Example call
CALL maintenance.usp_reindex_bloated_indexes_proc(
'10.75.154.3', 5432, 'postgres', 'DBMaintenanceUser', 'DBmaintenance@26',
NULL, ARRAY['postgres','template0','template1','cloudsqladmin'],
NULL, NULL,
20,          -- bloat threshold (free_percent, pgstattuple)
true,   --true means p_use_pgstattuple (estimator mode) and false means normal
false,    -- true means p_dry_run only and false means real run
0,
false,        -- always include PKs (set false to obey thresholds for PKs)
1048576,     -- min index size (skip tiny ones)
true,        -- use pgstatindex (fragmentation)
20           -- fragmentation threshold (leaf_fragmentation)
);


create extension pg_cron;

----------------------
SELECT cron.schedule(
  'DBMaintenance_REindex_WeeklyOnce',
  '30 17 * * 5',  --Friday 23:00 IST
  $$
  CALL maintenance.usp_reindex_bloated_indexes_proc(
'10.75.154.10', 5432, 'postgres', 'DBMaintenanceUser', 'DBmaintenance@26',
NULL, ARRAY['postgres','template0','template1','cloudsqladmin'],
NULL, NULL,
20,      -- bloat threshold %
true,   -- p_use_pgstattuple (estimator mode)
false,    -- true means p_dry_run only and false means real run
0,
false,        -- always include PKs (set false to obey thresholds for PKs)
1048576,     -- min index size (skip tiny ones)
true,        -- use pgstatindex (fragmentation)
20           -- fragmentation threshold (leaf_fragmentation)
);
$$
);


---change cmd or reschedule

SELECT cron.alter_job(
    job_id := 6,  -- The name of the job you are targeting
    schedule := NULL,             -- Pass NULL because we are NOT changing the schedule
    -- The new command you want the job to run is placed inside these dollar quotes
    command := $$
       CALL maintenance.usp_reindex_bloated_indexes_proc(
'10.80.220.13', 5432, 'postgres', 'DBMaintenanceUser', 'DBmaintenance@26',
NULL, ARRAY['postgres','template0','template1','cloudsqladmin'],
NULL, NULL,
20,      -- bloat threshold %
true,   -- p_use_pgstattuple (estimator mode)
false,    -- true means p_dry_run only and false means real run
0,
false,        -- always include PKs (set false to obey thresholds for PKs)
1048576,     -- min index size (skip tiny ones)
true,        -- use pgstatindex (fragmentation)
20           -- fragmentation threshold (leaf_fragmentation)
);
    $$
);
 
 
UPDATE cron.job SET database = 'og_db' WHERE jobid = 9;
 
select * from cron.job


-- Convenience queries
SET TIME ZONE 'Asia/Kolkata';
SELECT *
FROM maintenance.stats_update_run_log order by run_ts desc

truncate table maintenance.stats_update_run_log

 WHERE action IN ('PREFLIGHT_ROLE_REINDEX','PREFLIGHT_REINDEX')
 ORDER BY run_id DESC LIMIT 150;
SELECT run_id, run_ts, dbname, target, action, detail
FROM maintenance.stats_update_run_log
WHERE action = 'REINDEX_CANDIDATE'
ORDER BY run_id DESC LIMIT 150;
SELECT run_id, run_ts, dbname, target, action, success, detail
FROM maintenance.stats_update_run_log
WHERE action = 'REINDEX'
ORDER BY run_id DESC LIMIT 150;




-- Recently analyzed tables (last 30 minutes)
SELECT schemaname, relname, last_analyze, last_autoanalyze
FROM pg_stat_all_tables
WHERE greatest(last_analyze, last_autoanalyze) >= now() - interval '30 minutes'
ORDER BY schemaname, relname;

-- While analyze is running (PostgreSQL 13+)
SELECT pid, datname, relid::regclass AS table, sample_blks_total, sample_blks_scanned
FROM pg_stat_progress_analyze;

select * from cron.job


SELECT *
FROM "DBAdmin".pgstattuple('schema.index_name'::regclass);


SELECT relfilenode, relpages
FROM pg_class
WHERE relname = 'index_name';



