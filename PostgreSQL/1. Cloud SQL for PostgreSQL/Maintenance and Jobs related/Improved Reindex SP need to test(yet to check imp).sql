--- a/public.usp_reindex_bloated_indexes_proc.sql
+++ b/public.usp_reindex_bloated_indexes_proc.sql
@@
-CREATE OR REPLACE PROCEDURE public.usp_reindex_bloated_indexes_proc(
+CREATE OR REPLACE PROCEDURE public.usp_reindex_bloated_indexes_proc(
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
-    p_statement_timeout_ms integer DEFAULT 0                              -- 0=no timeout
+    p_statement_timeout_ms integer DEFAULT 0,                             -- 0=no timeout
+    p_max_reindexes_per_db integer DEFAULT NULL,                          -- cap per DB per run
+    p_pause_seconds numeric DEFAULT 0                                     -- pause between reindexes
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
+    v_detail_ex   text;
+    v_hint        text;
     -- preflight
     v_user_exists boolean;
     v_can_connect boolean;
     v_has_maintain boolean;
     v_detail      text;
     -- candidates
     r_idx         record;
+    v_done        integer;
     -- dynamic SQL text holders
     sql_candidates_est   text;
     sql_candidates_pgstat text;
 BEGIN
@@
-    PERFORM set_config('TimeZone', 'Asia/Kolkata', true);
+    PERFORM set_config('TimeZone', 'Asia/Kolkata', true);
+
+    ----------------------------------------------------------------------
+    -- Parameter validation
+    ----------------------------------------------------------------------
+    IF p_bloat_threshold_pct < 0 OR p_bloat_threshold_pct > 100 THEN
+        RAISE EXCEPTION 'p_bloat_threshold_pct must be between 0 and 100. Got: %', p_bloat_threshold_pct;
+    END IF;
+    IF p_pause_seconds < 0 THEN
+        RAISE EXCEPTION 'p_pause_seconds cannot be negative. Got: %', p_pause_seconds;
+    END IF;
+    IF p_max_reindexes_per_db IS NOT NULL AND p_max_reindexes_per_db < 0 THEN
+        RAISE EXCEPTION 'p_max_reindexes_per_db must be NULL or >= 0. Got: %', p_max_reindexes_per_db;
+    END IF;
+    IF p_include_dbs IS NOT NULL AND p_exclude_dbs IS NOT NULL THEN
+        RAISE NOTICE 'Both include and exclude lists provided; exclude will still be applied after include.';
+    END IF;
@@
-    EXCEPTION WHEN others THEN
-        GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
+    EXCEPTION WHEN others THEN
+        GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT,
+                                 v_detail_ex = PG_EXCEPTION_DETAIL, v_hint = PG_EXCEPTION_HINT;
         INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
-        VALUES (p_dbname, p_dbname, 'CONNECT', now(), now(), false,
-                format('meta dblink test failed: sqlstate=%s message=%s', v_sqlstate, v_msg));
+        VALUES (p_dbname, p_dbname, 'CONNECT', now(), now(), false,
+                format('meta dblink test failed: sqlstate=%s message=%s detail=%s hint=%s',
+                       coalesce(v_sqlstate,'?'), coalesce(v_msg,'?'), coalesce(v_detail_ex,'?'), coalesce(v_hint,'?')));
         RETURN;
     END;
@@
-    EXCEPTION WHEN others THEN
-        GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
+    EXCEPTION WHEN others THEN
+        GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT,
+                                 v_detail_ex = PG_EXCEPTION_DETAIL, v_hint = PG_EXCEPTION_HINT;
         INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
-        VALUES (p_dbname, '-', 'PREFLIGHT_ROLE_REINDEX', now(), now(), false,
-                format('preflight role check failed: sqlstate=%s message=%s', v_sqlstate, v_msg));
+        VALUES (p_dbname, '-', 'PREFLIGHT_ROLE_REINDEX', now(), now(), false,
+                format('preflight role check failed: sqlstate=%s message=%s detail=%s hint=%s',
+                       coalesce(v_sqlstate,'?'), coalesce(v_msg,'?'), coalesce(v_detail_ex,'?'), coalesce(v_hint,'?')));
     END;
@@
-        EXCEPTION WHEN others THEN
-            GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
+        EXCEPTION WHEN others THEN
+            GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT,
+                                     v_detail_ex = PG_EXCEPTION_DETAIL, v_hint = PG_EXCEPTION_HINT;
             INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
-            VALUES (db_row.datname, db_row.datname, 'PREFLIGHT_REINDEX', now(), now(), false,
-                    format('preflight db=%s failed: sqlstate=%s message=%s', db_row.datname, v_sqlstate, v_msg));
+            VALUES (db_row.datname, db_row.datname, 'PREFLIGHT_REINDEX', now(), now(), false,
+                    format('preflight db=%s failed: sqlstate=%s message=%s detail=%s hint=%s',
+                           db_row.datname, coalesce(v_sqlstate,'?'), coalesce(v_msg,'?'),
+                           coalesce(v_detail_ex,'?'), coalesce(v_hint,'?')));
         END;
     END LOOP;
@@
-    sql_candidates_est := $EST$
-        WITH bs AS (SELECT current_setting('block_size')::int AS bs),
-        idx AS (
-            SELECT i.indexrelid AS idx_oid,
-                   i.indrelid AS tbl_oid,
-                   n.nspname AS schema,
-                   c2.relname AS index_name,
-                   c.relname  AS table_name,
-                   c2.relpages AS ipages,
-                   c2.reltuples AS ituples
-            FROM pg_index i
-            JOIN pg_class c   ON c.oid  = i.indrelid
-            JOIN pg_class c2  ON c2.oid = i.indexrelid
-            JOIN pg_namespace n ON n.oid = c.relnamespace
-            WHERE c.relkind='r'
-              AND n.nspname NOT IN ('pg_catalog','information_schema','pg_toast')
-        ),
-        est AS (
-            SELECT schema, table_name, index_name,
-                   ipages, ituples,
-                   GREATEST(1, CEIL(ituples * 1.0))::bigint AS iotta
-            FROM idx
-        )
-        SELECT schema, table_name, index_name,
-               CASE WHEN iotta=0 OR ipages=0 THEN 0
-                    ELSE ROUND(100.0 * GREATEST(ipages - iotta,0)::numeric / NULLIF(ipages,0), 2)
-               END AS bloat_pct,
-               pg_relation_size(format('%I.%I', schema, index_name)) AS idx_bytes
-        FROM est
-    $EST$;
+    sql_candidates_est := $EST$
+        WITH idx AS (
+            SELECT i.indexrelid AS idx_oid,
+                   i.indrelid    AS tbl_oid,
+                   n.nspname     AS schema,
+                   c2.relname    AS index_name,
+                   c.relname     AS table_name,
+                   c2.relpages   AS ipages,
+                   c2.reltuples  AS ituples
+            FROM pg_index i
+            JOIN pg_class      c  ON c.oid  = i.indrelid
+            JOIN pg_class      c2 ON c2.oid = i.indexrelid
+            JOIN pg_namespace  n  ON n.oid  = c.relnamespace
+            WHERE c.relkind IN ('r','p')                 -- heap or partitioned
+              AND c2.relkind = 'i'                        -- index
+              AND i.indisvalid                            -- skip invalid indexes
+              AND n.nspname NOT IN ('pg_catalog','information_schema','pg_toast')
+        ),
+        est AS (
+            SELECT schema, table_name, index_name,
+                   ipages, ituples,
+                   GREATEST(1, CEIL(NULLIF(ituples,0)))::bigint AS iotta
+            FROM idx
+        )
+        SELECT schema, table_name, index_name,
+               CASE
+                 WHEN iotta = 0 OR ipages = 0 THEN 0
+                 ELSE ROUND(100.0 * GREATEST(ipages - iotta, 0)::numeric / NULLIF(ipages,0), 2)
+               END AS bloat_pct,
+               pg_relation_size(format('%I.%I', schema, index_name)) AS idx_bytes
+        FROM est
+    $EST$;
@@
-    sql_candidates_pgstat := $PGS$
-        SELECT n.nspname AS schema,
-               c.relname AS index_name,
-               ct.relname AS table_name,
-               (pgstattuple(c.oid)).free_percent::numeric(10,2) AS bloat_pct,
-               pg_relation_size(c.oid) AS idx_bytes
-        FROM pg_class c
-        JOIN pg_namespace n ON n.oid = c.relnamespace
-        JOIN pg_index i ON i.indexrelid = c.oid
-        JOIN pg_class ct ON ct.oid = i.indrelid
-        WHERE c.relkind='i'
-          AND n.nspname NOT IN ('pg_catalog','information_schema','pg_toast')
-    $PGS$;
+    sql_candidates_pgstat := $PGS$
+        SELECT n.nspname AS schema,
+               c.relname  AS index_name,
+               ct.relname AS table_name,
+               (pgstattuple(c.oid)).free_percent::numeric(10,2) AS bloat_pct,
+               pg_relation_size(c.oid) AS idx_bytes
+        FROM pg_class c
+        JOIN pg_namespace n ON n.oid = c.relnamespace
+        JOIN pg_index i      ON i.indexrelid = c.oid
+        JOIN pg_class ct     ON ct.oid = i.indrelid
+        WHERE c.relkind='i'
+          AND i.indisvalid
+          AND n.nspname NOT IN ('pg_catalog','information_schema','pg_toast')
+    $PGS$;
@@
         BEGIN
             PERFORM dblink_connect(conn_name, base_conn_str || format(' dbname=%L', db_row.datname));
             PERFORM dblink_exec(conn_name, 'SET TIME ZONE ''Asia/Kolkata''' ); -- remote IST
             IF p_statement_timeout_ms > 0 THEN
                 PERFORM dblink_exec(conn_name, format('SET statement_timeout=%s', p_statement_timeout_ms));
             END IF;
+            -- Hardening: avoid long waits on lightweight locks; keep path deterministic
+            PERFORM dblink_exec(conn_name, 'SET lock_timeout = 5000');                -- 5s
+            PERFORM dblink_exec(conn_name, 'SET search_path = pg_catalog, public');
         EXCEPTION WHEN others THEN
-            GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
+            GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT,
+                                     v_detail_ex = PG_EXCEPTION_DETAIL, v_hint = PG_EXCEPTION_HINT;
             INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
-            VALUES (db_row.datname, db_row.datname, 'CONNECT', now(), now(), false,
-                    format('connect failed: sqlstate=%s message=%s', v_sqlstate, v_msg));
+            VALUES (db_row.datname, db_row.datname, 'CONNECT', now(), now(), false,
+                    format('connect failed: sqlstate=%s message=%s detail=%s hint=%s',
+                           coalesce(v_sqlstate,'?'), coalesce(v_msg,'?'),
+                           coalesce(v_detail_ex,'?'), coalesce(v_hint,'?')));
             CONTINUE;
         END;
@@
-        IF p_use_pgstattuple THEN
+        v_done := 0;
+        IF p_use_pgstattuple THEN
             -- Ensure extension exists; if not, log and fallback to estimator.
             BEGIN
                 PERFORM dblink_exec(conn_name, 'CREATE EXTENSION IF NOT EXISTS pgstattuple');
             EXCEPTION WHEN others THEN
-                GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
+                GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT,
+                                         v_detail_ex = PG_EXCEPTION_DETAIL, v_hint = PG_EXCEPTION_HINT;
                 INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
-                VALUES (db_row.datname, '-', 'REINDEX_CANDIDATES', now(), now(), false,
-                        format('pgstattuple not available: sqlstate=%s message=%s; using estimator', v_sqlstate, v_msg));
+                VALUES (db_row.datname, '-', 'REINDEX_CANDIDATES', now(), now(), false,
+                        format('pgstattuple not available: sqlstate=%s message=%s detail=%s hint=%s; using estimator',
+                               coalesce(v_sqlstate,'?'), coalesce(v_msg,'?'),
+                               coalesce(v_detail_ex,'?'), coalesce(v_hint,'?')));
                 p_use_pgstattuple := false;
             END;
         END IF;
@@
-            FOR r_idx IN
-                SELECT * FROM dblink(conn_name, sql_candidates_pgstat)
-                AS t(schema text, index_name text, table_name text, bloat_pct numeric, idx_bytes bigint)
-                WHERE (p_schema_filter IS NULL OR schema = p_schema_filter)
-                  AND (p_index_name_like IS NULL OR index_name ILIKE p_index_name_like)
-                  AND bloat_pct >= p_bloat_threshold_pct
-                ORDER BY bloat_pct DESC
+            FOR r_idx IN
+                SELECT *
+                FROM dblink(conn_name, sql_candidates_pgstat)
+                     AS t(schema text, index_name text, table_name text, bloat_pct numeric, idx_bytes bigint)
+                WHERE (p_schema_filter IS NULL OR schema = p_schema_filter)
+                  AND (p_index_name_like IS NULL OR index_name ILIKE p_index_name_like)
+                  AND bloat_pct >= p_bloat_threshold_pct
+                ORDER BY (idx_bytes * (bloat_pct/100.0)) DESC NULLS LAST
+                LIMIT COALESCE(p_max_reindexes_per_db, 2147483647)
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
@@
-                IF NOT p_dry_run THEN
+                IF NOT p_dry_run THEN
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
+                        v_done := v_done + 1;
+                        IF p_pause_seconds > 0 THEN
+                            PERFORM pg_sleep(p_pause_seconds);
+                        END IF;
                     EXCEPTION WHEN others THEN
-                        GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
+                        GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT,
+                                                 v_detail_ex = PG_EXCEPTION_DETAIL, v_hint = PG_EXCEPTION_HINT;
                         INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
                         VALUES (db_row.datname,
                                 format('%s.%s', r_idx.schema, r_idx.index_name),
                                 'REINDEX',
-                                now(), now(), false,
-                                format('reindex failed: sqlstate=%s message=%s', v_sqlstate, v_msg));
+                                now(), now(), false,
+                                format('reindex failed: sqlstate=%s message=%s detail=%s hint=%s',
+                                       coalesce(v_sqlstate,'?'), coalesce(v_msg,'?'),
+                                       coalesce(v_detail_ex,'?'), coalesce(v_hint,'?')));
                     END;
                 END IF;
             END LOOP;
         ELSE
             -- Estimator mode (no extension). Based on wiki bloat approach (approx).
-            FOR r_idx IN
-                SELECT * FROM dblink(conn_name, sql_candidates_est)
-                AS t(schema text, table_name text, index_name text, bloat_pct numeric, idx_bytes bigint)
-                WHERE (p_schema_filter IS NULL OR schema = p_schema_filter)
-                  AND (p_index_name_like IS NULL OR index_name ILIKE p_index_name_like)
-                  AND bloat_pct >= p_bloat_threshold_pct
-                ORDER BY bloat_pct DESC
+            FOR r_idx IN
+                SELECT *
+                FROM dblink(conn_name, sql_candidates_est)
+                     AS t(schema text, table_name text, index_name text, bloat_pct numeric, idx_bytes bigint)
+                WHERE (p_schema_filter IS NULL OR schema = p_schema_filter)
+                  AND (p_index_name_like IS NULL OR index_name ILIKE p_index_name_like)
+                  AND bloat_pct >= p_bloat_threshold_pct
+                ORDER BY (idx_bytes * (bloat_pct/100.0)) DESC NULLS LAST
+                LIMIT COALESCE(p_max_reindexes_per_db, 2147483647)
             LOOP
                 INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
                 VALUES (db_row.datname,
                         format('%s.%s', r_idx.schema, r_idx.index_name),
                         'REINDEX_CANDIDATE',
                         now(), now(), true,
                         format('mode=estimator bloat_pct=%s size=%s',
                                round(r_idx.bloat_pct::numeric, 2)::text,
                                pg_size_pretty(r_idx.idx_bytes)));
@@
-                IF NOT p_dry_run THEN
+                IF NOT p_dry_run THEN
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
+                        v_done := v_done + 1;
+                        IF p_pause_seconds > 0 THEN
+                            PERFORM pg_sleep(p_pause_seconds);
+                        END IF;
                     EXCEPTION WHEN others THEN
-                        GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT;
+                        GET STACKED DIAGNOSTICS v_sqlstate = RETURNED_SQLSTATE, v_msg = MESSAGE_TEXT,
+                                                 v_detail_ex = PG_EXCEPTION_DETAIL, v_hint = PG_EXCEPTION_HINT;
                         INSERT INTO maintenance.stats_update_run_log(dbname, target, action, started_at, finished_at, success, detail)
                         VALUES (db_row.datname,
                                 format('%s.%s', r_idx.schema, r_idx.index_name),
                                 'REINDEX',
-                                now(), now(), false,
-                                format('reindex failed: sqlstate=%s message=%s', v_sqlstate, v_msg));
+                                now(), now(), false,
+                                format('reindex failed: sqlstate=%s message=%s detail=%s hint=%s',
+                                       coalesce(v_sqlstate,'?'), coalesce(v_msg,'?'),
+                                       coalesce(v_detail_ex,'?'), coalesce(v_hint,'?')));
                     END;
                 END IF;
             END LOOP;
         END IF;
@@
         PERFORM dblink_disconnect(conn_name);
     END LOOP;
 END;
 $proc$;




----------------------------

CALL public.usp_reindex_bloated_indexes_proc(
  '10.80.220.13', 5432, 'postgres', 'DBMaintenanceUser', '***use secret***',
  NULL, ARRAY['postgres','template0','template1','cloudsqladmin'],
  NULL, NULL,
  40,        -- bloat threshold %
  true,      -- use pgstattuple when available
  false,     -- do real reindexing (set true for dry-run)
  1800000,   -- 30m statement timeout per statement
  50,        -- reindex at most 50 indexes per DB per run
  1.0        -- 1 second pause between reindexes
);