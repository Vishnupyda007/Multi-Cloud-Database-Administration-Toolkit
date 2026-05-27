--call security.disable_cognizant_empid_roles()

create schema security;
CREATE TABLE security.cognizant_empid_role_access_audit (
    rolname text,
    action text,
    action_time timestamptz default now()
);

select * from security.cognizant_empid_role_access_audit; 

CREATE OR REPLACE PROCEDURE security.disable_cognizant_empid_roles()
LANGUAGE plpgsql
AS $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT rolname
        FROM pg_roles
        WHERE rolcanlogin = true
          AND rolname LIKE '%@cognizant.com'
          AND rolname NOT IN (
              'postgres',
              'cloudsqladmin'
          )
    LOOP
        EXECUTE format('ALTER ROLE %I NOLOGIN', r.rolname);
		INSERT INTO security.cognizant_empid_role_access_audit VALUES (r.rolname, 'NOLOGIN', now());
        RAISE NOTICE 'Disabled login for role: %', r.rolname;
    END LOOP;
END;
$$;


SELECT cron.schedule(
    'disable_cognizant_roles_8pm_ist',
    '30 14 * * *',
    $$CALL security.disable_cognizant_empid_roles();$$
);


