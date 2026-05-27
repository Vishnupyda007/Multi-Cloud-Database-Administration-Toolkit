
CREATE OR REPLACE PROCEDURE public.usp_update_stats_all_user_dbs_proc(
    p_host                  text,
    p_port                  integer,
    p_dbname                text,      -- metadata DB to enumerate pg_database (e.g., 'postgres')
    p_user                  text,
    p_password              text,
    p_include_dbs           text[] DEFAULT NULL,                                 -- only these DBs
    p_exclude_dbs           text[] DEFAULT ARRAY['postgres','template0','template1'], -- default excludes
    p_schema_filter         text DEFAULT NULL,                                   -- e.g., 'public'
    p_table_name_like       text DEFAULT NULL,                                   -- e.g., 'sales%' (ILIKE)
    p_use_per_table         boolean DEFAULT true,                                -- true=iterate tables; false=whole DB
    p_vacuum_before         boolean DEFAULT false,                               -- true=VACUUM (ANALYZE)
    p_statement_timeout_ms  integer DEFAULT 0                                    -- 0=no timeout
)
LANGUAGE plpgsql
AS $proc$
DECLARE
    base_conn_str   text;
    meta_conn_str   text;
    sql_list_dbs    text;
    db_row          record;
    conn_name       text;
    started_ts      timestamptz;
    finished_ts     timestamptz;
    cmd             text;
    sql_tables      text;
    tbl_row         record;
    analyzed_cnt    bigint;
    v_sqlstate      text;
    v_msg           text;
BEGIN
    -- Force SSL and quote conninfo values to handle special characters safely
    base_conn_str := format(
        'host=%L port=%L user=%L password=%L sslmode=require connect_timeout=5',
        p_host, p_port::text, p_user, p_password
    );
    meta_conn_str := base_conn_str || format(' dbname=%L', p_dbname);

    -- Remote SQL without placeholders; filters applied locally
    sql_list_dbs := $q$
        SELECT datname
        FROM pg_database
        WHERE datallowconn
          AND NOT datistemplate
        ORDER BY datname
    $q$;

    -- Meta dblink sanity test; if it fails, log and exit
    BEGIN
        PERFORM 1 FROM dblink(meta_conn_str, 'SELECT 1') AS t(x int);
    EXCEPTION WHEN others THEN
        GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
        INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
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

        -- Connect to each database with SSL required
        BEGIN
            PERFORM dblink_connect(conn_name, base_conn_str || format(' dbname=%L', db_row.datname));
        EXCEPTION WHEN others THEN
            GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
            INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
            VALUES (db_row.datname, db_row.datname, 'CONNECT', now(), now(), false,
                    format('connect failed: sqlstate=%s message=%s', v_sqlstate, v_msg));
            CONTINUE;
        END;

        -- Optional timeout
        IF p_statement_timeout_ms IS NOT NULL AND p_statement_timeout_ms > 0 THEN
            PERFORM dblink_exec(conn_name, format('SET statement_timeout = %s', p_statement_timeout_ms));
        END IF;

        IF NOT p_use_per_table THEN
            -- Whole-DB ANALYZE or VACUUM(ANALYZE)
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
                INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
                VALUES (db_row.datname, db_row.datname, cmd, started_ts, finished_ts, true,
                        format('analyzed_tables=%s', coalesce(analyzed_cnt, 0)));
            EXCEPTION WHEN others THEN
                GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
                finished_ts := now();
                INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
                VALUES (db_row.datname, db_row.datname, cmd, started_ts, finished_ts, false,
                        format('exec failed: sqlstate=%s message=%s', v_sqlstate, v_msg));
            END;

        ELSE
            -- Per-table mode with optional filters
            sql_tables := $q$
                SELECT n.nspname::text AS schemaname,
                       c.relname::text AS relname
                FROM pg_class c
                JOIN pg_namespace n ON n.oid = c.relnamespace
                WHERE c.relkind IN ('r','p','m')    -- heap, partitioned table, matview
                  AND n.nspname NOT IN ('pg_catalog','information_schema','pg_toast')
            $q$;

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
                started_ts := now();
                IF p_vacuum_before THEN
                    cmd := format('VACUUM (ANALYZE) %I.%I', tbl_row.schemaname, tbl_row.relname);
                ELSE
                    cmd := format('ANALYZE %I.%I', tbl_row.schemaname, tbl_row.relname);
                END IF;

                BEGIN
                    PERFORM dblink_exec(conn_name, cmd);

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
                    INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
                    VALUES (db_row.datname,
                            format('%s.%s', tbl_row.schemaname, tbl_row.relname),
                            split_part(cmd, ' ', 1) || ' ' || split_part(cmd, ' ', 2),
                            started_ts, finished_ts, true,
                            format('analyzed=%s', coalesce(analyzed_cnt, 0)));
                EXCEPTION WHEN others THEN
                    GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
                    finished_ts := now();
                    INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
                    VALUES (db_row.datname,
                            format('%s.%s', tbl_row.schemaname, tbl_row.relname),
                            split_part(cmd, ' ', 1) || ' ' || split_part(cmd, ' ', 2),
                            started_ts, finished_ts, false,
                            format('table exec failed: %I.%I sqlstate=%s message=%s',
                                   tbl_row.schemaname, tbl_row.relname, v_sqlstate, v_msg));
                END;
            END LOOP;
        END IF;

        PERFORM dblink_disconnect(conn_name);
    END LOOP;
END;
$proc$;





CALL public.usp_update_stats_all_user_dbs_proc(
    '10.75.154.9', 5432, 'postgres', 'test_maintenanceUser', 'Test@2026',
    NULL, ARRAY['postgres','template0','template1','cloudsqladmin'],
    NULL, NULL,
    true,  --false means whole db, true- per-table
    false, -- ANALYZE
    0
);


-- Run on the server; shows whether your maintenance role can CONNECT
SELECT datname,
       has_database_privilege('test_maintenanceUser', datname, 'CONNECT') AS can_connect
FROM pg_database
WHERE datallowconn AND NOT datistemplate
ORDER BY datname;


DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT datname
    FROM pg_database
    WHERE datallowconn AND NOT datistemplate
  LOOP
    EXECUTE format('GRANT CONNECT ON DATABASE %I TO %I', r.datname, 'test_maintenanceUser');
  END LOOP;
END$$;



-- PostgreSQL 16+: global analyze permission via predefined role
GRANT pg_stat_scan_tables TO "test_maintenanceUser";
GRANT pg_maintain TO "test_maintenanceUser";

-- Or: per table/schema grants if you prefer finer control
-- (example) GRANT ANALYZE ON TABLE public.some_table TO test_maintenanceUser;

-- Last run, show failures first
SELECT dbname, target, action, success, detail, started_at, finished_at
FROM maintenance.stats_update_run_log
ORDER BY run_ts DESC, success ASC, dbname, target
LIMIT 100;







SELECT *
FROM dblink(
  'host=''10.75.154.9'' port=''5432'' dbname=''postgres'' user=''postgres'' password=''8>z{&knxM\OyHud:''  connect_timeout=5',
  'SELECT current_database(), current_user'
) AS t(dbname text, dbuser text);


SELECT *
FROM dblink(
  'host=''10.75.154.9'' port=''5432'' dbname=''postgres'' user=''test_maintenanceUser'' password=''Test@2026'' sslmode=require connect_timeout=5',
  'SELECT current_database(), current_user'
) AS t(dbname text, dbuser text);



SHOW ssl;                -- should be on
SHOW ssl_min_protocol_version;
