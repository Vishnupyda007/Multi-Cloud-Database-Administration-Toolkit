CREATE SERVER atsEDSuat_db_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host '10.75.156.3', dbname 'ent_data_store', port '5432');

create USER MAPPING FOR "OneC_4681"
  SERVER atsEDSuat_db_server
  OPTIONS (user 'OneC_4681', password '$1c4681@NonProd');

  CREATE USER MAPPING FOR postgres
  SERVER atsEDSuat_db_server
  OPTIONS (user 'OneC_4681', password '$1c4681@NonProd');

  

CREATE USER MAPPING FOR "ats-4681-np-sa@cb0104074a-citnonprod-gc.iam"
  SERVER atsEDSuat_db_server
  OPTIONS (user 'OneC_4681', password '$1c4681@NonProd');


 ALTER SERVER atsEDSuat_db_server OPTIONS (
  ADD fetch_size         '2000',    -- fetch 2000 rows per network round trip
  ADD connect_timeout    '10',      -- give up connecting after 10 seconds
   --ADD extensions         'pg_trgm', pushdown trigram operators to source
  ADD fdw_startup_cost   '150',     -- slightly higher than default for Cloud SQL network
  ADD fdw_tuple_cost     '0.05',    -- source is fast, rows are cheap to fetch
  ADD use_remote_estimate 'true'    -- ask source for real row counts before planning
);

-- Apply statement and lock timeouts via options string
ALTER SERVER atsEDSuat_db_server OPTIONS (
  ADD options '-c statement_timeout=15000 -c lock_timeout=5000'
); 

IMPORT FOREIGN SCHEMA public
  FROM SERVER atsedsuat_db_server
  INTO ent_data_store_fdw;  --local_schema

 DO $$
DECLARE r record;
BEGIN
    FOR r IN
        SELECT foreign_table_name
        FROM information_schema.foreign_tables
        WHERE foreign_table_schema = 'ent_data_store_fdw'
          AND foreign_table_name NOT LIKE 'vw\_%' ESCAPE '\'
          AND foreign_table_name NOT LIKE '%\_view' ESCAPE '\'
    LOOP
        EXECUTE format(
            'DROP FOREIGN TABLE ent_data_store_fdw.%I',
            r.foreign_table_name
        );
    END LOOP;
END $$;



UPDATE cron.job
	SET active=false
	WHERE jobid=8;
	
select * from cron.job

SELECT cron.schedule_in_database(
  'refresh_fdw_EDS_views_OneC_5013_PT',
  '*/10 * * * *',
  'select "DBAdmin".refresh_fdw_edsviews_func()',
  'OneC_5013'
);