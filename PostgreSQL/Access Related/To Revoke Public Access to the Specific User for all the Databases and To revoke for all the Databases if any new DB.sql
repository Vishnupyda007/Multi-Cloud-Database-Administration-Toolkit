-------------------------------------------------------------
To revoke Public access to all the user databases for a specific user: Run this script once user is created:

 
DO $$
DECLARE
  r RECORD;
  target_role CONSTANT TEXT := 'test'; --provide the user/role name
BEGIN
  FOR r IN
    SELECT datname
    FROM pg_database
    WHERE datistemplate = false
      AND datname not in ('cloudsqladmin','postgres') --excluding the system databases
  LOOP
    RAISE NOTICE 'Revoking CONNECT on database % from role %', r.datname, target_role;
    EXECUTE format('REVOKE CONNECT ON DATABASE %I FROM %I;', r.datname, target_role);
  END LOOP;
END;
$$ LANGUAGE plpgsql;
 


------------------------
To revoke public Access for all the User Databases whenever new DB is created:


DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT datname
    FROM pg_database
    WHERE datistemplate = false
      AND datname not in  ('postgres','cloudsqladmin')
  LOOP
    EXECUTE format('REVOKE CONNECT ON DATABASE %I FROM PUBLIC;', r.datname);
  END LOOP;
END;
$$