
-- DROP FUNCTION IF EXISTS public.usp_update_stats_all_user_dbs(
--   text, integer, text, text, text, text[], text[], text, text, boolean, boolean, integer);

CREATE OR REPLACE FUNCTION public.usp_update_stats_all_user_dbs(
    p_host                  text,
    p_port                  integer,
    p_dbname                text,      -- metadata DB to enumerate pg_database (e.g., 'postgres')
    p_user                  text,
    p_password              text,
    p_include_dbs           text[] DEFAULT NULL,
    p_exclude_dbs           text[] DEFAULT ARRAY['postgres','template0','template1'],
    p_schema_filter         text DEFAULT NULL,
    p_table_name_like       text DEFAULT NULL,
    p_use_per_table         boolean DEFAULT true,
    p_vacuum_before         boolean DEFAULT false,
    p_statement_timeout_ms  integer DEFAULT 0
)
RETURNS TABLE (
    dbname       text,
    target       text,
    action       text,
    started_at   timestamptz,
    finished_at  timestamptz,
    success      boolean,
    detail       text
)
LANGUAGE plpgsql
AS $func$
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
    detail_msg      text;
    v_sqlstate      text;
    v_msg           text;
BEGIN
    -- Quoted conninfo values + sslmode=prefer + connect_timeout
    base_conn_str := format(
        'host=%L port=%L user=%L password=%L sslmode=prefer connect_timeout=5',
        p_host, p_port::text, p_user, p_password
    );
    meta_conn_str := base_conn_str || format(' dbname=%L', p_dbname);

    -- Remote SQL with no placeholders; filter locally
    sql_list_dbs := $q$
        SELECT datname
        FROM pg_database
        WHERE datallowconn
          AND NOT datistemplate
        ORDER BY datname
    $q$;

    -- Quick meta dblink test for clearer errors
    BEGIN
        PERFORM 1 FROM dblink(meta_conn_str, 'SELECT 1') AS t(x int);
    EXCEPTION WHEN others THEN
        GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
        RETURN QUERY
          SELECT p_dbname, p_dbname, 'CONNECT', now(), now(), false,
                 format('meta dblink test failed: sqlstate=%s message=%s', v_sqlstate, v_msg);
        RETURN;
    END;

    FOR db_row IN
        SELECT datname
        FROM dblink(meta_conn_str, sql_list_dbs) AS t(datname text)
        WHERE (p_include_dbs IS NULL OR datname = ANY(p_include_dbs))
          AND (p_exclude_dbs IS NULL OR NOT (datname = ANY(p_exclude_dbs)))
    LOOP
        dbname := db_row.datname;
        conn_name := 'analyze_' || dbname || '_' || replace(md5(random()::text), '-', '');

        BEGIN
            PERFORM dblink_connect(conn_name, base_conn_str || format(' dbname=%L', dbname));
        EXCEPTION WHEN others THEN
            GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
            started_ts := now();
            finished_ts := now();
            cmd := '(CONNECT) ' || base_conn_str || format(' dbname=%L', dbname);
            RETURN QUERY SELECT dbname, dbname, 'CONNECT', started_ts, finished_ts, false,
                         format('connect failed: sqlstate=%s message=%s', v_sqlstate, v_msg);
            CONTINUE;
        END;

        IF p_statement_timeout_ms IS NOT NULL AND p_statement_timeout_ms > 0 THEN
            PERFORM dblink_exec(conn_name, format('SET statement_timeout = %s', p_statement_timeout_ms));
        END IF;

        IF NOT p_use_per_table THEN
            started_ts := now();
            IF p_vacuum_before THEN
                action := 'VACUUM (ANALYZE)';
                cmd := 'VACUUM (ANALYZE)';
            ELSE
                action := 'ANALYZE';
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
                detail_msg := format('analyzed_tables=%s', coalesce(analyzed_cnt, 0));
                RETURN QUERY SELECT dbname, dbname, action, started_ts, finished_ts, true, detail_msg;
            EXCEPTION WHEN others THEN
                GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
                finished_ts := now();
                RETURN QUERY SELECT dbname, dbname, action, started_ts, finished_ts, false,
                             format('exec failed: sqlstate=%s message=%s', v_sqlstate, v_msg);
            END;

        ELSE
            sql_tables := $q$
                SELECT n.nspname::text AS schemaname,
                       c.relname::text AS relname
                FROM pg_class c
                JOIN pg_namespace n ON n.oid = c.relnamespace
                WHERE c.relkind IN ('r','p','m')
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
                target := format('%s.%s', tbl_row.schemaname, tbl_row.relname);
                started_ts := now();

                IF p_vacuum_before THEN
                    action := 'VACUUM (ANALYZE)';
                    cmd := format('VACUUM (ANALYZE) %I.%I', tbl_row.schemaname, tbl_row.relname);
                ELSE
                    action := 'ANALYZE';
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
                    detail_msg := format('analyzed=%s', coalesce(analyzed_cnt, 0));
                    RETURN QUERY SELECT dbname, target, action, started_ts, finished_ts, true, detail_msg;
                EXCEPTION WHEN others THEN
                    GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
                    finished_ts := now();
                    RETURN QUERY SELECT dbname, target, action, started_ts, finished_ts, false,
                                 format('table exec failed: %I.%I sqlstate=%s message=%s',
                                        tbl_row.schemaname, tbl_row.relname, v_sqlstate, v_msg);
                END;
            END LOOP;
        END IF;

        PERFORM dblink_disconnect(conn_name);
    END LOOP;
END;
$func$;










-- Whole DB analyze (fast, low lock)
SELECT *
FROM public.usp_update_stats_all_user_dbs(
  '10.75.154.9', 5432, 'postgres', 'postgres', '8>z{&knxM\OyHud:',
  NULL, ARRAY['postgres','template0','template1'],
  NULL, NULL,
  false,  -- whole DB
  false,  -- ANALYZE only
  0
);



SELECT *
FROM public.usp_update_stats_all_user_dbs(
    '10.75.154.9',
    5432,
    'postgres',
    'postgres',
    '8>z{&knxM\OyHud:',
    NULL,
    ARRAY['postgres','template0','template1'],
    NULL,
    NULL,
    true,   -- per-table
    false,  -- ANALYZE
    0
);


SELECT *
FROM public.usp_update_stats_all_user_dbs(
    '10.75.154.9',     -- Cloud SQL private IP or hostname
    5432,
    'postgres',        -- metadata DB for pg_database enumeration
    'postgres',        -- user
    '8>z{&knxM\OyHud:',   -- password
    NULL,              -- include_dbs (NULL = all user DBs)
    ARRAY['template0','template1'], -- exclude system DBs
    NULL,              -- schema_filter
    NULL,              -- table_name_like
    true,              -- per-table mode (safer on busy systems)
    false,             -- ANALYZE (no VACUUM)
    0                  -- statement_timeout_ms
);


-- Per-table in 'public', with name filter, and VACUUM (ANALYZE)
SELECT *
FROM public.usp_update_stats_all_user_dbs(
  '10.0.0.5', 5432, 'postgres', 'deploytool', '***',
  NULL, ARRAY['postgres','template0','template1'],
  'public', 'sales',
  true,   -- per-table
  true,   -- VACUUM (ANALYZE)
  0
);







SELECT *
FROM dblink(
  'host=''10.75.154.9'' port=''5432'' dbname=''postgres'' user=''postgres'' password=''8>z{&knxM\OyHud:'' connect_timeout=600',
  'SELECT current_database(), current_user'
) AS t(dbname text, dbuser text);




-- Recently analyzed tables (last 30 minutes)
SELECT schemaname, relname, last_analyze, last_autoanalyze
FROM pg_stat_all_tables
WHERE greatest(last_analyze, last_autoanalyze) >= now() - interval '30 minutes'
ORDER BY schemaname, relname;

-- While analyze is running (PostgreSQL 13+)
SELECT pid, datname, relid::regclass AS table, sample_blks_total, sample_blks_scanned
FROM pg_stat_progress_analyze;


