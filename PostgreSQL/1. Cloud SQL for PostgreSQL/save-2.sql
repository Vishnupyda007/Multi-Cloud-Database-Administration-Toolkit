
CREATE OR REPLACE VIEW public.vw_employee
 AS
 SELECT id,
    name,
    datatime
   FROM "Employee";

ALTER TABLE public.vw_employee
    OWNER TO postgres;

GRANT ALL ON TABLE public.vw_employee TO postgres;
GRANT SELECT ON TABLE public.vw_employee TO testpoc;




SELECT cron.schedule_in_database(
  'scheduled-vacuum-full',
  '0 3 15 11 *',  -- cron format: min hour day month weekday
  'VACUUM FULL public.my_table;',
  'TrailPoC_DB'
);


grant connect on database "TrailPoC_DB" to test;
grant usage on schema public to test;
grant select on public.vw_employee to test;

select * from pg_settings

 REVOKE CONNECT ON DATABASE og_db FROM PUBLIC;
 REVOKE CONNECT ON DATABASE postgres_learning_env FROM PUBLIC;


 REVOKE USAGE ON SCHEMA public FROM PUBLIC;


REVOKE CONNECT ON DATABASE template1 FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM PUBLIC;

create database test1_db template template1

SELECT * 
FROM pg_stat_activity
WHERE datname = 'template1'
  AND pid <> pg_backend_pid(); -- Exclude your own session


 select pg_terminate_backend(903007)






 
 