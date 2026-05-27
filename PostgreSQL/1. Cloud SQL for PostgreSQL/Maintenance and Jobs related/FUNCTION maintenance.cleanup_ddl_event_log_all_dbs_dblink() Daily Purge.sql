--create this function in Postgres Db,and have delete access for our login on the given table
--GRANT USAGE ON SCHEMA cron TO "DBMaintenanceUser";
--GRANT EXECUTE ON FUNCTION cron.schedule(text, text, text) TO "DBMaintenanceUser";


CREATE OR REPLACE FUNCTION maintenance.cleanup_ddl_event_log_all_dbs_dblink()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
    v_host     text := '10.75.154.5';     -- private/public IP of Cloud SQL instance
    v_user     text := 'DBMaintenanceUser';
    v_pass     text := 'DBmaintenance@26';

    db         record;
    conn_name  text;
    conn_str   text;
    tbl_exists boolean;
BEGIN
    FOR db IN
        SELECT datname
        FROM pg_database
        WHERE datallowconn
          AND NOT datistemplate
          AND datname NOT IN ('postgres','template0','template1','cloudsqladmin')
    LOOP
        conn_name := 'ddlclean_' || db.datname;

        conn_str := format(
            'host=%s dbname=%L user=%L password=%L',
            v_host, db.datname, v_user, v_pass
        );

        BEGIN
            PERFORM dblink_connect(conn_name, conn_str);

            SELECT x.exists_flag
              INTO tbl_exists
            FROM dblink(
                conn_name,
                $q$
                SELECT EXISTS (
                    SELECT 1
                    FROM information_schema.tables
                    WHERE table_schema = 'DBAdmin'
                      AND table_name   = 'ddl_event_log'
                ) AS exists_flag
                $q$
            ) AS x(exists_flag boolean);

            IF tbl_exists THEN
                PERFORM dblink_exec(
                    conn_name,
                    $del$
                    DELETE FROM "DBAdmin".ddl_event_log
                    WHERE log_time < now() - interval '15 days';
                    $del$
                );
            END IF;

            PERFORM dblink_disconnect(conn_name);

        EXCEPTION WHEN OTHERS THEN
            BEGIN
                PERFORM dblink_disconnect(conn_name);
            EXCEPTION WHEN OTHERS THEN
                NULL;
            END;

            RAISE NOTICE 'Cleanup failed/skipped for database %: %', db.datname, SQLERRM;
            CONTINUE;
        END;
    END LOOP;
END;
$$;

--select maintenance.cleanup_ddl_event_log_all_dbs_dblink()

SELECT cron.schedule(
  'ddl_event_log_cleanup_all_dbs',
  '30 3 * * *',
  $$SELECT maintenance.cleanup_ddl_event_log_all_dbs_dblink();$$
);

