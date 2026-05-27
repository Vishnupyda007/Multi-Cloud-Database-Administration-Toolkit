-- Ensure dblink (once per DB where you install the proc)
CREATE EXTENSION IF NOT EXISTS dblink;

-- Recreate the procedure with autovacuum guard + per-table time budget (skip)
CREATE OR REPLACE PROCEDURE maintenance.usp_update_stats_all_user_dbs_proc(
    p_host        text,
    p_port        integer,
    p_dbname      text,                  -- metadata DB to enumerate pg_database (e.g., 'postgres')
    p_user        text,
    p_password    text,
    p_include_dbs text[] DEFAULT NULL,   -- only these DBs
    p_exclude_dbs text[] DEFAULT ARRAY['postgres','template0','template1','cloudsqladmin'],
    p_schema_filter   text DEFAULT NULL, -- e.g., 'public'
    p_table_name_like text DEFAULT NULL, -- e.g., 'sales%' (ILIKE)
    p_use_per_table   boolean DEFAULT true,   -- true=iterate tables; false=whole DB
    p_vacuum_before   boolean DEFAULT false,  -- true=VACUUM (ANALYZE), false=ANALYZE
    p_statement_timeout_ms integer DEFAULT 0, -- 0=no timeout

    -- Autovacuum pressure guard
    p_autovacuum_max_inflight integer DEFAULT 2,   -- pause if active autovacuum workers > this
    p_autovacuum_wait_secs    integer DEFAULT 300, -- total wait budget per guard (seconds)

    -- NEW: per-table total time budget (wait + prep). If exceeded, SKIP table.
    p_per_table_max_secs      integer DEFAULT 600  -- 10 minutes per table
)
LANGUAGE plpgsql
AS $proc$
DECLARE
    base_conn_str text;
    meta_conn_str text;
    sql_list_dbs  text;

    db_row        record;
    conn_name     text;

    started_ts    timestamptz;
    finished_ts   timestamptz;
    cmd           text;
    sql_tables    text;
    tbl_row       record;
    analyzed_cnt  bigint;

    v_sqlstate    text;
    v_msg         text;

    -- guard working vars
    av_workers    integer;
    waited        integer;
    sleep_step    integer := 5;     -- seconds between checks
    did_wait      boolean;          -- for logging once per scope

    -- per-table skip guard
    table_start_ts timestamptz;
    elapsed_secs   integer;
BEGIN
    ----------------------------------------------------------------------
    -- Force IST for this session (affects now(), logs)
    ----------------------------------------------------------------------
    PERFORM set_config('TimeZone', 'Asia/Kolkata', true);

    -- Build conninfo; require SSL (Cloud SQL / managed)
    base_conn_str := format(
        'host=%L port=%L user=%L password=%L sslmode=require connect_timeout=5',
        p_host, p_port::text, p_user, p_password
    );
    meta_conn_str := base_conn_str || format(' dbname=%L', p_dbname);

    -- Enumerate user DBs
    sql_list_dbs := $Q$
        SELECT datname
        FROM pg_database
        WHERE datallowconn
          AND NOT datistemplate
        ORDER BY datname
    $Q$;

    -- Meta connectivity sanity
    BEGIN
        PERFORM 1 FROM dblink(meta_conn_str, 'SELECT 1') AS t(x int);
    EXCEPTION WHEN others THEN
        GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
        INSERT INTO maintenance.stats_update_run_log
               (dbname, target, action, started_at, finished_at, success, detail)
        VALUES (p_dbname, p_dbname, 'CONNECT', now(), now(), false,
                format('meta dblink test failed: sqlstate=%s message=%s', v_sqlstate, v_msg));
        RETURN;
    END;

    FOR db_row IN
        SELECT datname
        FROM dblink(meta_conn_str, sql_list_dbs) AS t(datname text)
        WHERE (p_include_dbs IS NULL OR datname = ANY(p_include_dbs))
          AND (p_exclude_dbs IS NULL OR NOT (datname = ANY(p_exclude_dbs)))
    LOOP
        conn_name := 'analyze_' || db_row.datname || '_' || replace(md5(random()::text), '-', '');

        -- Connect to each database
        BEGIN
            PERFORM dblink_connect(conn_name, base_conn_str || format(' dbname=%L', db_row.datname));
            PERFORM dblink_exec(conn_name, 'SET TIME ZONE ''Asia/Kolkata'''); -- remote IST
        EXCEPTION WHEN others THEN
            GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
            INSERT INTO maintenance.stats_update_run_log
                   (dbname, target, action, started_at, finished_at, success, detail)
            VALUES (db_row.datname, db_row.datname, 'CONNECT', now(), now(), false,
                    format('connect failed: sqlstate=%s message=%s', v_sqlstate, v_msg));
            CONTINUE;
        END;

        -- Optional per-session timeout in remote DB
        IF p_statement_timeout_ms IS NOT NULL AND p_statement_timeout_ms > 0 THEN
            PERFORM dblink_exec(conn_name, format('SET statement_timeout = %s', p_statement_timeout_ms));
        END IF;

        ------------------------------------------------------------------
        -- Whole-DB path
        ------------------------------------------------------------------
        IF NOT p_use_per_table THEN
            -- Autovacuum guard (cluster-level for whole-DB op)
            did_wait := false;
            waited   := 0;
            LOOP
                BEGIN
                    SELECT w INTO av_workers
                    FROM dblink(conn_name, $C$
                        WITH a AS (
                          SELECT count(*) AS c FROM pg_stat_activity
                          WHERE backend_type = 'autovacuum worker'
                        ),
                        b AS (
                          SELECT count(*) AS c FROM pg_stat_activity
                          WHERE query ILIKE 'autovacuum:%'
                        )
                        SELECT COALESCE((SELECT c FROM a), (SELECT c FROM b)) AS w
                    $C$) AS t(w int);
                EXCEPTION WHEN others THEN
                    av_workers := 0; -- if not available, do not block
                END;

                EXIT WHEN av_workers <= p_autovacuum_max_inflight OR waited >= p_autovacuum_wait_secs;

                PERFORM dblink_exec(conn_name, format('SELECT pg_sleep(%s)', sleep_step));
                waited  := waited + sleep_step;
                did_wait := true;
            END LOOP;

            IF did_wait THEN
                INSERT INTO maintenance.stats_update_run_log
                       (dbname, target, action, started_at, finished_at, success, detail)
                VALUES (db_row.datname, db_row.datname, 'AV_GUARD_WAIT', now(), now(), true,
                        format('paused for autovacuum: max_inflight=%s waited=%ss current_workers=%s',
                               p_autovacuum_max_inflight, waited, av_workers));
            END IF;

            -- Issue ANALYZE / VACUUM(ANALYZE)
            started_ts := now();
            IF p_vacuum_before THEN
                cmd := 'VACUUM (ANALYZE)';
            ELSE
                cmd := 'ANALYZE';
            END IF;

            BEGIN
                PERFORM dblink_exec(conn_name, cmd);

                SELECT cnt INTO analyzed_cnt
                FROM dblink(conn_name,
                    format(
                        'SELECT count(*)::bigint
                         FROM pg_stat_all_tables
                         WHERE (last_analyze >= %L OR last_autoanalyze >= %L)',
                        started_ts, started_ts
                    )
                ) AS t(cnt bigint);

                finished_ts := now();
                INSERT INTO maintenance.stats_update_run_log
                       (dbname, target, action, started_at, finished_at, success, detail)
                VALUES (db_row.datname, db_row.datname, cmd, started_ts, finished_ts, true,
                        format('analyzed_tables=%s', coalesce(analyzed_cnt, 0)));
            EXCEPTION WHEN others THEN
                GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
                finished_ts := now();
                INSERT INTO maintenance.stats_update_run_log
                       (dbname, target, action, started_at, finished_at, success, detail)
                VALUES (db_row.datname, db_row.datname, cmd, started_ts, finished_ts, false,
                        format('exec failed: sqlstate=%s message=%s', v_sqlstate, v_msg));
            END;

        ------------------------------------------------------------------
        -- Per-table path with per-table time budget (skip)
        ------------------------------------------------------------------
        ELSE
            sql_tables := $T$
                SELECT n.nspname::text AS schemaname,
                       c.relname::text AS relname
                FROM pg_class c
                JOIN pg_namespace n ON n.oid = c.relnamespace
                WHERE c.relkind IN ('r','p','m') -- heap, partitioned, matview
                  AND n.nspname NOT IN ('pg_catalog','information_schema','pg_toast')
            $T$;

            IF p_schema_filter IS NOT NULL THEN
                sql_tables := sql_tables || format(' AND n.nspname = %L', p_schema_filter);
            END IF;
            IF p_table_name_like IS NOT NULL THEN
                sql_tables := sql_tables || format(' AND c.relname ILIKE %L', '%' || p_table_name_like || '%');
            END IF;

            sql_tables := sql_tables || ' ORDER BY n.nspname, c.relname';

            FOR tbl_row IN
                SELECT schemaname, relname
                FROM dblink(conn_name, sql_tables) AS t(schemaname text, relname text)
            LOOP
                -- Start per-table timer
                table_start_ts := clock_timestamp();
                did_wait       := false;
                waited         := 0;

                -- Autovacuum guard loop (with per-table budget)
                LOOP
                    -- Compute elapsed seconds since table started
                    elapsed_secs := EXTRACT(EPOCH FROM (clock_timestamp() - table_start_ts))::int;

                    -- If we already exceeded per-table budget, SKIP this table
                    IF elapsed_secs >= p_per_table_max_secs THEN
                        INSERT INTO maintenance.stats_update_run_log
                               (dbname, target, action, started_at, finished_at, success, detail)
                        VALUES (db_row.datname,
                                format('%s.%s', tbl_row.schemaname, tbl_row.relname),
                                'SKIP_PER_TABLE_BUDGET',
                                table_start_ts, clock_timestamp(), true,
                                format('skipped after %ss: per-table max=%ss; (guard waited so far=%ss)',
                                       elapsed_secs, p_per_table_max_secs, waited));
                        -- move to next table
                        CONTINUE;
                    END IF;

                    -- Count autovacuum workers
                    BEGIN
                        SELECT w INTO av_workers
                        FROM dblink(conn_name, $C$
                            WITH a AS (
                              SELECT count(*) AS c FROM pg_stat_activity
                              WHERE backend_type = 'autovacuum worker'
                            ),
                            b AS (
                              SELECT count(*) AS c FROM pg_stat_activity
                              WHERE query ILIKE 'autovacuum:%'
                            )
                            SELECT COALESCE((SELECT c FROM a), (SELECT c FROM b)) AS w
                        $C$) AS t(w int);
                    EXCEPTION WHEN others THEN
                        av_workers := 0;
                    END;

                    -- Exit guard if pressure low OR we exhausted guard wait budget
                    EXIT WHEN av_workers <= p_autovacuum_max_inflight
                              OR waited >= p_autovacuum_wait_secs;

                    -- If sleeping would exceed per-table budget, SKIP before sleep
                    IF (elapsed_secs + sleep_step) >= p_per_table_max_secs THEN
                        INSERT INTO maintenance.stats_update_run_log
                               (dbname, target, action, started_at, finished_at, success, detail)
                        VALUES (db_row.datname,
                                format('%s.%s', tbl_row.schemaname, tbl_row.relname),
                                'SKIP_PER_TABLE_BUDGET',
                                table_start_ts, clock_timestamp(), true,
                                format('skipped: next sleep would exceed per-table max (elapsed=%ss, max=%ss)',
                                       elapsed_secs, p_per_table_max_secs));
                        CONTINUE; -- next table
                    END IF;

                    -- Sleep a bit and continue waiting
                    PERFORM dblink_exec(conn_name, format('SELECT pg_sleep(%s)', sleep_step));
                    waited   := waited + sleep_step;
                    did_wait := true;
                END LOOP;

                -- Log if we did wait for autovacuum for this table
                IF did_wait THEN
                    INSERT INTO maintenance.stats_update_run_log
                           (dbname, target, action, started_at, finished_at, success, detail)
                    VALUES (db_row.datname,
                            format('%s.%s', tbl_row.schemaname, tbl_row.relname),
                            'AV_GUARD_WAIT', table_start_ts, clock_timestamp(), true,
                            format('paused for autovacuum: max_inflight=%s waited=%ss current_workers=%s',
                                   p_autovacuum_max_inflight, waited, av_workers));
                END IF;

                -- Re-check budget before executing maintenance
                elapsed_secs := EXTRACT(EPOCH FROM (clock_timestamp() - table_start_ts))::int;
                IF elapsed_secs >= p_per_table_max_secs THEN
                    INSERT INTO maintenance.stats_update_run_log
                           (dbname, target, action, started_at, finished_at, success, detail)
                    VALUES (db_row.datname,
                            format('%s.%s', tbl_row.schemaname, tbl_row.relname),
                            'SKIP_PER_TABLE_BUDGET',
                            table_start_ts, clock_timestamp(), true,
                            format('skipped before exec: elapsed=%ss >= per-table max=%ss',
                                   elapsed_secs, p_per_table_max_secs));
                    CONTINUE;
                END IF;

                -- Compose and run the command
                started_ts := now();
                IF p_vacuum_before THEN
                    cmd := format('VACUUM (ANALYZE) %I.%I', tbl_row.schemaname, tbl_row.relname);
                ELSE
                    cmd := format('ANALYZE %I.%I', tbl_row.schemaname, tbl_row.relname);
                END IF;

                BEGIN
                    PERFORM dblink_exec(conn_name, cmd);

                    -- Verify success for this table
                    SELECT cnt INTO analyzed_cnt
                    FROM dblink(conn_name,
                        format(
                            'SELECT CASE
                                 WHEN (st.last_analyze >= %L OR st.last_autoanalyze >= %L) THEN 1
                                 ELSE 0
                             END::bigint
                             FROM pg_stat_all_tables st
                             WHERE st.schemaname = %L AND st.relname = %L',
                            started_ts, started_ts, tbl_row.schemaname, tbl_row.relname
                        )
                    ) AS t(cnt bigint);

                    finished_ts := now();

                    IF coalesce(analyzed_cnt, 0) = 1 THEN
                        INSERT INTO maintenance.stats_update_run_log
                               (dbname, target, action, started_at, finished_at, success, detail)
                        VALUES (db_row.datname,
                                format('%s.%s', tbl_row.schemaname, tbl_row.relname),
                                split_part(cmd, ' ', 1) || ' ' || split_part(cmd, ' ', 2),
                                started_ts, finished_ts, true,
                                'analyzed=1');
                    ELSE
                        INSERT INTO maintenance.stats_update_run_log
                               (dbname, target, action, started_at, finished_at, success, detail)
                        VALUES (db_row.datname,
                                format('%s.%s', tbl_row.schemaname, tbl_row.relname),
                                split_part(cmd, ' ', 1) || ' ' || split_part(cmd, ' ', 2),
                                started_ts, finished_ts, false,
                                'analyzed=0 (no timestamp change detected)');
                    END IF;

                EXCEPTION WHEN others THEN
                    GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
                    finished_ts := now();
                    INSERT INTO maintenance.stats_update_run_log
                           (dbname, target, action, started_at, finished_at, success, detail)
                    VALUES (db_row.datname,
                            format('%s.%s', tbl_row.schemaname, tbl_row.relname),
                            split_part(cmd, ' ', 1) || ' ' || split_part(cmd, ' ', 2),
                            started_ts, finished_ts, false,
                            format('table exec failed: %I.%I sqlstate=%s message=%s',
                                   tbl_row.schemaname, tbl_row.relname, v_sqlstate, v_msg));
                END;
            END LOOP; -- each table
        END IF; -- per-table vs whole-DB

        PERFORM dblink_disconnect(conn_name);
    END LOOP; -- each DB
END;
$proc$;