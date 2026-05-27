-- PROCEDURE: security.disable_cognizant_empid_roles()

-- DROP PROCEDURE IF EXISTS security.enable_cognizant_empid_roles();

CREATE OR REPLACE PROCEDURE security.enable_cognizant_empid_roles(
	)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT rolname
        FROM pg_roles
        WHERE rolcanlogin = false
          AND rolname LIKE '%@cognizant.com'
          AND rolname NOT IN (
              'postgres',
              'cloudsqladmin'
          )
    LOOP
        EXECUTE format('ALTER ROLE %I LOGIN', r.rolname);
		INSERT INTO security.cognizant_empid_role_access_audit VALUES (r.rolname, 'LOGIN', now());
        RAISE NOTICE 'Enabled login for role: %', r.rolname;
    END LOOP;
END;
$BODY$;



SELECT cron.schedule(
    'enable_cognizant_roles_8am_ist',   -- job name
    '30 2 * * *',                        -- 2:30 AM UTC = 8:00 AM IST
    'CALL security.enable_cognizant_empid_roles()'
);