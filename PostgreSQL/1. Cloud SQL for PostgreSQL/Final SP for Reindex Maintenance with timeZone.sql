
CREATE OR REPLACE PROCEDURE public.usp_reindex_bloated_indexes_proc(
    p_host text,
    p_port integer,
    p_dbname text,                  -- meta DB to enumerate pg_database (e.g., 'postgres')
    p_user text,
    p_password text,
    p_include_dbs text[] DEFAULT NULL,                                    -- only these DBs
    p_exclude_dbs text[] DEFAULT ARRAY['postgres','template0','template1','cloudsqladmin'],
    p_schema_filter text DEFAULT NULL,                                    -- e.g., 'public'
    p_index_name_like text DEFAULT NULL,                                  -- e.g., '%cust%'
    p_bloat_threshold_pct numeric DEFAULT 40,                             -- threshold %
    p_use_pgstattuple boolean DEFAULT false,                              -- precise mode (requires extension)
    p_dry_run boolean DEFAULT true,                                       -- log only
    p_statement_timeout_ms integer DEFAULT 0                              -- 0=no timeout
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
    -- candidates
    r_idx         record;
    -- dynamic SQL text holders
    sql_candidates_est   text;
    sql_candidates_pgstat text;
BEGIN
    ----------------------------------------------------------------------
    -- Force IST for this session; all inserts/now() render in Asia/Kolkata.
    ----------------------------------------------------------------------
    PERFORM set_config('TimeZone', 'Asia/Kolkata', true);

    -- dblink conninfos (SSL required on Cloud SQL)
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
    -- PREFLIGHT: cluster-wide role membership (pg_maintain / MAINTAIN) + user
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
    -- Candidate SQL (Estimator — community bloat query, no extensions)
    -- Simplified: compute index bloat percentage and size.
    ----------------------------------------------------------------------
    sql_candidates_est := $EST$
        WITH bs AS (SELECT current_setting('block_size')::int AS bs),
        idx AS (
            SELECT i.indexrelid AS idx_oid,
                   i.indrelid AS tbl_oid,
                   n.nspname AS schema,
                   c2.relname AS index_name,
                   c.relname  AS table_name,
                   c2.relpages AS ipages,
                   c2.reltuples AS ituples
            FROM pg_index i
            JOIN pg_class c   ON c.oid  = i.indrelid
            JOIN pg_class c2  ON c2.oid = i.indexrelid
            JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE c.relkind='r'
              AND n.nspname NOT IN ('pg_catalog','information_schema','pg_toast')
        ),
        est AS (
            SELECT schema, table_name, index_name,
                   ipages, ituples,
                   GREATEST(1, CEIL(ituples * 1.0))::bigint AS iotta
            FROM idx
        )
        SELECT schema, table_name, index_name,
               CASE WHEN iotta=0 OR ipages=0 THEN 0
                    ELSE ROUND(100.0 * GREATEST(ipages - iotta,0)::numeric / NULLIF(ipages,0), 2)
               END AS bloat_pct,
               pg_relation_size(format('%I.%I', schema, index_name)) AS idx_bytes
        FROM est
    $EST$;

    ----------------------------------------------------------------------
    -- Candidate SQL (pgstattuple precise) — requires CREATE EXTENSION.
    ----------------------------------------------------------------------
    sql_candidates_pgstat := $PGS$
        SELECT n.nspname AS schema,
               c.relname AS index_name,
               ct.relname AS table_name,
               (pgstattuple(c.oid)).free_percent::numeric(10,2) AS bloat_pct,
               pg_relation_size(c.oid) AS idx_bytes
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        JOIN pg_index i ON i.indexrelid = c.oid
        JOIN pg_class ct ON ct.oid = i.indrelid
        WHERE c.relkind='i'
          AND n.nspname NOT IN ('pg_catalog','information_schema','pg_toast')
    $PGS$;

    ----------------------------------------------------------------------
    -- MAIN LOOP: connect per DB, list candidates, reindex concurrently
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

        -- Build candidate list
        IF p_use_pgstattuple THEN
            -- Ensure extension exists; if not, log and fallback to estimator.
            BEGIN
                PERFORM dblink_exec(conn_name, 'CREATE EXTENSION IF NOT EXISTS pgstattuple');
            EXCEPTION WHEN others THEN
                GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
                INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
                VALUES (db_row.datname, '-', 'REINDEX_CANDIDATES', now(), now(), false,
                        format('pgstattuple not available: sqlstate=%s message=%s; using estimator', v_sqlstate, v_msg));
                p_use_pgstattuple := false;
            END;
        END IF;

        IF p_use_pgstattuple THEN
            FOR r_idx IN
                SELECT * FROM dblink(conn_name, sql_candidates_pgstat)
                AS t(schema text, index_name text, table_name text, bloat_pct numeric, idx_bytes bigint)
                WHERE (p_schema_filter IS NULL OR schema = p_schema_filter)
                  AND (p_index_name_like IS NULL OR index_name ILIKE p_index_name_like)
                  AND bloat_pct >= p_bloat_threshold_pct
                ORDER BY bloat_pct DESC
            LOOP
                -- Log candidate
                INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
                VALUES (db_row.datname,
                        format('%s.%s', r_idx.schema, r_idx.index_name),
                        'REINDEX_CANDIDATE',
                        now(), now(), true,
                        format('mode=pgstattuple bloat_pct=%s size=%s',
                               round(r_idx.bloat_pct::numeric, 2)::text,
                               pg_size_pretty(r_idx.idx_bytes)));

                -- Reindex (unless dry run)
                IF NOT p_dry_run THEN
                    BEGIN
                        PERFORM dblink_exec(conn_name,
                            format('REINDEX INDEX CONCURRENTLY %I.%I', r_idx.schema, r_idx.index_name));
                        -- doc: CONCURRENTLY uses lower lock; rebuilds index safely.
                        INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
                        VALUES (db_row.datname,
                                format('%s.%s', r_idx.schema, r_idx.index_name),
                                'REINDEX',
                                now(), now(), true,
                                format('reindexed concurrently (pgstattuple bloat=%s%%)',
                                       round(r_idx.bloat_pct::numeric, 2)::text));
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
        ELSE
            -- Estimator mode (no extension). Based on wiki bloat approach (approx).
            FOR r_idx IN
                SELECT * FROM dblink(conn_name, sql_candidates_est)
                AS t(schema text, table_name text, index_name text, bloat_pct numeric, idx_bytes bigint)
                WHERE (p_schema_filter IS NULL OR schema = p_schema_filter)
                  AND (p_index_name_like IS NULL OR index_name ILIKE p_index_name_like)
                  AND bloat_pct >= p_bloat_threshold_pct
                ORDER BY bloat_pct DESC
            LOOP
                INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
                VALUES (db_row.datname,
                        format('%s.%s', r_idx.schema, r_idx.index_name),
                        'REINDEX_CANDIDATE',
                        now(), now(), true,
                        format('mode=estimator bloat_pct=%s size=%s',
                               round(r_idx.bloat_pct::numeric, 2)::text,
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
                                format('reindexed concurrently (est bloat=%s%%)',
                                       round(r_idx.bloat_pct::numeric, 2)::text));
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






-- Example call
CALL public.usp_reindex_bloated_indexes_proc(
'10.75.154.9', 5432, 'postgres', 'test_maintenanceUser', 'Test@2026',
NULL, ARRAY['postgres','template0','template1','cloudsqladmin'],
NULL, NULL,
40,      -- bloat threshold %
false,   -- p_use_pgstattuple (estimator mode)
true,    -- p_dry_run
0
);

-- Convenience queries
SET TIME ZONE 'Asia/Kolkata';
SELECT run_id, run_ts, dbname, target, action, success, detail
FROM maintenance.stats_update_run_log
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
