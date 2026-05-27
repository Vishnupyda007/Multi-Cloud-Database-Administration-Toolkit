
CREATE OR REPLACE PROCEDURE maintenance.usp_update_stats_all_user_dbs_proc (
  p_host text,
  p_port integer,
  p_dbname text, -- metadata DB to enumerate pg_database (e.g., 'postgres')
  p_user text,
  p_password text,
  p_include_dbs text[] DEFAULT NULL, -- only these DBs
  p_exclude_dbs text[] DEFAULT ARRAY['postgres','template0','template1','cloudsqladmin'], -- default excludes
  p_schema_filter text DEFAULT NULL,  -- e.g., 'public'
  p_table_name_like text DEFAULT NULL, -- e.g., 'sales%' (ILIKE)
  p_use_per_table boolean DEFAULT true, -- true=iterate tables; false=whole DB
  p_vacuum_before boolean DEFAULT false, -- true=VACUUM (ANALYZE)
  p_statement_timeout_ms integer DEFAULT 0 -- 0=no timeout
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
  -------------------------------------------------------------------------
  -- Force IST time zone for this procedure session (affects now(), inserts)
  -------------------------------------------------------------------------
  PERFORM set_config('TimeZone', 'Asia/Kolkata', true);

  -- Build conninfo; require SSL for Cloud SQL
  base_conn_str := format(
    'host=%L port=%L user=%L password=%L sslmode=require connect_timeout=5',
    p_host, p_port::text, p_user, p_password
  );
  meta_conn_str := base_conn_str || format(' dbname=%L', p_dbname);

  -- List user databases (filters applied locally)
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

    -- Connect to each database
    BEGIN
      PERFORM dblink_connect(conn_name, base_conn_str || format(' dbname=%L', db_row.datname));

      -------------------------------------------------------------------------
      -- Ensure remote session (inside the target DB) is also set to IST
      -------------------------------------------------------------------------
      PERFORM dblink_exec(conn_name, 'SET TIME ZONE ''Asia/Kolkata''');

    EXCEPTION WHEN others THEN
      GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
      INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
      VALUES (db_row.datname, db_row.datname, 'CONNECT', now(), now(), false,
              format('connect failed: sqlstate=%s message=%s', v_sqlstate, v_msg));
      CONTINUE;
    END;

    -- Optional timeout per DB
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
      -- Per-table mode with filters
      sql_tables := $q$
        SELECT n.nspname::text AS schemaname,
               c.relname::text AS relname
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE c.relkind IN ('r','p','m') -- heap, partitioned table, matview
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
          -- Execute maintenance command
          PERFORM dblink_exec(conn_name, cmd);

          -- Success check via stats timestamps
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

          IF coalesce(analyzed_cnt, 0) = 1 THEN
            finished_ts := now();
            INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
            VALUES (db_row.datname,
                    format('%s.%s', tbl_row.schemaname, tbl_row.relname),
                    split_part(cmd, ' ', 1) || ' ' || split_part(cmd, ' ', 2),
                    started_ts, finished_ts, true,
                    'analyzed=1');
          ELSE
            -- ========== DIAGNOSTICS FOR analyzed=0 ==========
            DECLARE
              has_rel        boolean := NULL;
              has_lock       boolean := NULL;
              being_analyzed boolean := NULL;
              owner_name     text    := NULL;
              diag_detail    text    := NULL;
            BEGIN
              -- Existence
              SELECT exists_rel INTO has_rel
              FROM dblink(conn_name,
                format(
                  $$SELECT EXISTS (
                       SELECT 1 FROM pg_class c
                       JOIN pg_namespace n ON n.oid = c.relnamespace
                       WHERE n.nspname = %L AND c.relname = %L
                     ) AS exists_rel$$,
                  tbl_row.schemaname, tbl_row.relname
                )
              ) AS t(exists_rel boolean);

              IF NOT coalesce(has_rel, false) THEN
                diag_detail := 'analyzed=0 reason=not-found';
              ELSE
                -- Locks that commonly block analyze
                SELECT has_blocking_lock INTO has_lock
                FROM dblink(conn_name,
                  format(
                    $$SELECT EXISTS (
                         SELECT 1
                         FROM pg_locks l
                         JOIN pg_class c ON c.oid = l.relation
                         JOIN pg_namespace n ON n.oid = c.relnamespace
                         WHERE n.nspname = %L AND c.relname = %L
                           AND l.granted = true
                           AND l.mode IN ('AccessExclusiveLock','ShareRowExclusiveLock','RowExclusiveLock')
                       ) AS has_blocking_lock$$,
                    tbl_row.schemaname, tbl_row.relname
                  )
                ) AS t(has_blocking_lock boolean);

                IF coalesce(has_lock, false) THEN
                  diag_detail := 'analyzed=0 reason=lock-contention';
                ELSE
                  -- Ownership (for privilege inference)
                  SELECT owner INTO owner_name
                  FROM dblink(conn_name,
                    format(
                      $$SELECT (SELECT rolname
                                FROM pg_roles r
                                JOIN pg_class c ON c.relowner = r.oid
                                JOIN pg_namespace n ON n.oid = c.relnamespace
                                WHERE n.nspname = %L AND c.relname = %L) AS owner$$,
                      tbl_row.schemaname, tbl_row.relname
                    )
                  ) AS t(owner text);

                  -- Optional: concurrent analyze progress (version-dependent)
                  BEGIN
                    SELECT being_analyzed_now INTO being_analyzed
                    FROM dblink(conn_name,
                      format(
                        $$SELECT EXISTS (
                             SELECT 1
                             FROM pg_stat_progress_analyze spa
                             JOIN pg_class c ON c.oid = spa.relid
                             JOIN pg_namespace n ON n.oid = c.relnamespace
                             WHERE n.nspname = %L AND c.relname = %L
                           ) AS being_analyzed_now$$,
                        tbl_row.schemaname, tbl_row.relname
                      )
                    ) AS t(being_analyzed_now boolean);
                  EXCEPTION WHEN undefined_table THEN
                    -- pg_stat_progress_analyze may not exist
                    being_analyzed := FALSE;
                  END;

                  IF coalesce(being_analyzed, false) THEN
                    diag_detail := 'analyzed=0 reason=concurrent-autoanalyze';
                  ELSE
                    -- Permission is the likely cause if not owner and role lacks MAINTAIN/ANALYZE
                    diag_detail := format('analyzed=0 reason=permission owner=%s', coalesce(owner_name,'?'));
                  END IF;
                END IF;
              END IF;

              finished_ts := now();
              INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
              VALUES (db_row.datname,
                      format('%s.%s', tbl_row.schemaname, tbl_row.relname),
                      split_part(cmd, ' ', 1) || ' ' || split_part(cmd, ' ', 2),
                      started_ts, finished_ts, false,
                      diag_detail);
            END;
            -- ========== END DIAGNOSTICS ==========
          END IF;

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

      END LOOP; -- each table
    END IF;

    PERFORM dblink_disconnect(conn_name);
  END LOOP; -- each DB
END;
$proc$;


GRANT EXECUTE ON PROCEDURE maintenance.usp_update_stats_all_user_dbs_proc TO "DBMaintenanceUser";


grant all on table maintenance.stats_update_run_log TO "DBMaintenanceUser";



CALL maintenance.usp_update_stats_all_user_dbs_proc(
  '10.80.220.13', 5432, 'postgres', 'DBMaintenanceUser', 'DBmaintenance@26',
  NULL, ARRAY['postgres','template0','template1','cloudsqladmin'],
  NULL, NULL,
  true,  -- false means whole DB; true per-table
  true,  -- false means ANALYZE (vs true means VACUUM (ANALYZE))
  0
);



SELECT cron.schedule(
  'DBMaintenance_update_stats_every_2_days',
  '30 16 */2 * *',
  $$
  CALL maintenance.usp_update_stats_all_user_dbs_proc(
    '10.80.220.13', 5432, 'postgres', 'DBMaintenanceUser', 'DBmaintenance@26',
    NULL, ARRAY['postgres','template0','template1','cloudsqladmin'],
    NULL, NULL,
    true,
    true,
    0
  );
  $$
);


---to skip on Friday
SELECT cron.schedule(
  'DBMaintenance_update_stats_every_2_days',
  '30 16 */2 * *',
  $cron$
  DO $pl$
  BEGIN
    -- Skip Friday (ISO day-of-week: Monday=1 ... Sunday=7)
    IF EXTRACT(ISODOW FROM (now() AT TIME ZONE 'Asia/Kolkata')) = 5 THEN
      RAISE NOTICE 'Skipping Friday run at % (Asia/Kolkata)', now() AT TIME ZONE 'Asia/Kolkata';
      RETURN;
    END IF;

    CALL maintenance.usp_update_stats_all_user_dbs_proc(
      '10.80.154.10', 5432, 'postgres', 'DBMaintenanceUser', 'DBmaintenance@26',
      NULL, ARRAY['postgres','template0','template1','cloudsqladmin'],
      NULL, NULL,
      true,
      true,
      0
    );
  END
  $pl$;
  $cron$
);


SELECT cron.alter_job(
    job_id := 1,  -- The name of the job you are targeting
    schedule := NULL,             -- Pass NULL because we are NOT changing the schedule
    -- The new command you want the job to run is placed inside these dollar quotes
    command := $$
       $cron$
  DO $pl$
  BEGIN
    -- Skip Friday (ISO day-of-week: Monday=1 ... Sunday=7)
    IF EXTRACT(ISODOW FROM (now() AT TIME ZONE 'Asia/Kolkata')) = 5 THEN
      RAISE NOTICE 'Skipping Friday run at % (Asia/Kolkata)', now() AT TIME ZONE 'Asia/Kolkata';
      RETURN;
    END IF;

    CALL maintenance.usp_update_stats_all_user_dbs_proc(
      '10.75.151.3', 5432, 'postgres', 'DBMaintenanceUser', 'DBmaintenance@26',
      NULL, ARRAY['postgres','template0','template1','cloudsqladmin'],
      NULL, NULL,
      true,
      true,
      0
    );
  END
  $pl$;
  $cron$
    $$
);


SET TIME ZONE 'Asia/Kolkata';
SELECT dbname, target, action, success, detail, started_at, finished_at
FROM maintenance.stats_update_run_log
ORDER BY started_at DESC, success ASC, dbname, target
LIMIT 150;



-- Recently analyzed tables (last 30 minutes)
SELECT schemaname, relname, last_analyze, last_autoanalyze
FROM pg_stat_all_tables
WHERE greatest(last_analyze, last_autoanalyze) >= now() - interval '30 minutes'
ORDER BY schemaname, relname;

-- While analyze is running (PostgreSQL 13+)
SELECT pid, datname, relid::regclass AS table, sample_blks_total, sample_blks_scanned
FROM pg_stat_progress_analyze;


select * from cron.job