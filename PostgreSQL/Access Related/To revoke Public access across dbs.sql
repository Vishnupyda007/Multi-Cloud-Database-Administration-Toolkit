-- Ensure dblink is available (Cloud SQL: user must be in cloudsqlsuperuser)
CREATE EXTENSION IF NOT EXISTS dblink;

-- Optional: capture results / errors
DROP TABLE IF EXISTS tmp_public_hardening_log;
CREATE TEMP TABLE tmp_public_hardening_log(
  database text,
  step     text,
  outcome  text
);

DO $$
DECLARE
  -- If inet_server_addr() returns NULL (socket connection), we use this fallback:
   fallback_host text := '10.75.154.9';   -- e.g., '10.75.154.5' (private IP) or your public IP
  port          int  := 5432;
  usr           text := 'postgres';
  pwd           text := '8>z{&knxM\OyHud:';

  detected_host text;
  rdb record;
  conn_str text;
  inner_sql text;
BEGIN
  -- Prefer the live server IP; otherwise use your fallback host/IP.
  SELECT COALESCE(host(inet_server_addr()), fallback_host) INTO detected_host;

  FOR rdb IN
    SELECT datname
    FROM pg_database
    WHERE datname NOT IN ('template0', 'cloudsqladmin')
      -- uncomment the next line if you do NOT want to touch template1
      -- AND datname <> 'template1'
  LOOP
    BEGIN
      conn_str := format('host=%s port=%s dbname=%s user=%s password=%s',
                         detected_host, port, rdb.datname, usr, pwd);

      -- open a named dblink connection per database
      PERFORM dblink_connect(rdb.datname, conn_str);

      -- Everything below runs INSIDE the target DB
      inner_sql := $q$

        -- 1) Revoke PUBLIC at database level (CONNECT, TEMP)  — affects new connections
        DO $do$
        BEGIN
          EXECUTE 'REVOKE CONNECT, TEMP ON DATABASE '
                  || quote_ident(current_database()) || ' FROM PUBLIC';
        END $do$;

        -- 2) Revoke PUBLIC on the `public` schema (USAGE, CREATE)
        REVOKE USAGE, CREATE ON SCHEMA public FROM PUBLIC;

        -- 3) Remove ALL default-privilege grants to PUBLIC (global and IN SCHEMA public),
        --    irrespective of original grantor. We loop pg_default_acl; for each owner with
        --    PUBLIC grantee we:
        --      a) ensure membership (GRANT owner TO current_user) so ALTER DEFAULT PRIVILEGES is allowed
        --      b) issue the appropriate ALTER DEFAULT PRIVILEGES ... REVOKE ... FROM PUBLIC
        --      c) drop the temporary membership
        DO $do$
        DECLARE
          rec record;
        BEGIN
          FOR rec IN
            SELECT
              da.defaclrole,                            -- owner oid
              pg_get_userbyid(da.defaclrole) AS owner,  -- owner name
              da.defaclobjtype,                         -- 'r','S','f','T','n'
              n.nspname AS schema_name,
              EXISTS (
                SELECT 1
                FROM aclexplode(coalesce(da.defaclacl, acldefault(da.defaclobjtype, da.defaclrole))) x
                WHERE x.grantee = 0                      -- PUBLIC
              ) AS has_public
            FROM pg_default_acl da
            LEFT JOIN pg_namespace n ON n.oid = da.defaclnamespace
            WHERE EXISTS (
              SELECT 1
              FROM aclexplode(coalesce(da.defaclacl, acldefault(da.defaclobjtype, da.defaclrole))) x
              WHERE x.grantee = 0
            )
          LOOP
            -- Step (a): ensure we are a member of the owner role to change its default privileges
            BEGIN
              EXECUTE format('GRANT %I TO %I', rec.owner, current_user);
            EXCEPTION WHEN OTHERS THEN
              -- ignore if already a member or grant not needed
            END;

            -- Step (b): revoke all PUBLIC default privileges for this owner/object-type/scope
            IF rec.defaclobjtype = 'r' THEN
              -- TABLES
              IF rec.schema_name IS NULL THEN
                EXECUTE format(
                  'ALTER DEFAULT PRIVILEGES FOR ROLE %I REVOKE ALL ON TABLES FROM PUBLIC',
                  rec.owner
                );
              ELSE
                EXECUTE format(
                  'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I REVOKE ALL ON TABLES FROM PUBLIC',
                  rec.owner, rec.schema_name
                );
              END IF;

            ELSIF rec.defaclobjtype = 'S' THEN
              -- SEQUENCES
              IF rec.schema_name IS NULL THEN
                EXECUTE format(
                  'ALTER DEFAULT PRIVILEGES FOR ROLE %I REVOKE ALL ON SEQUENCES FROM PUBLIC',
                  rec.owner
                );
              ELSE
                EXECUTE format(
                  'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I REVOKE ALL ON SEQUENCES FROM PUBLIC',
                  rec.owner, rec.schema_name
                );
              END IF;

            ELSIF rec.defaclobjtype = 'f' THEN
              -- FUNCTIONS/ROUTINES
              IF rec.schema_name IS NULL THEN
                EXECUTE format(
                  'ALTER DEFAULT PRIVILEGES FOR ROLE %I REVOKE ALL ON FUNCTIONS FROM PUBLIC',
                  rec.owner
                );
              ELSE
                EXECUTE format(
                  'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I REVOKE ALL ON FUNCTIONS FROM PUBLIC',
                  rec.owner, rec.schema_name
                );
              END IF;

            ELSIF rec.defaclobjtype = 'T' THEN
              -- TYPES (including domains)
              IF rec.schema_name IS NULL THEN
                EXECUTE format(
                  'ALTER DEFAULT PRIVILEGES FOR ROLE %I REVOKE ALL ON TYPES FROM PUBLIC',
                  rec.owner
                );
              ELSE
                EXECUTE format(
                  'ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA %I REVOKE ALL ON TYPES FROM PUBLIC',
                  rec.owner, rec.schema_name
                );
              END IF;

            ELSIF rec.defaclobjtype = 'n' THEN
              -- SCHEMAS (note: there is NO "IN SCHEMA" variant for SCHEMAS)
              EXECUTE format(
                'ALTER DEFAULT PRIVILEGES FOR ROLE %I REVOKE ALL ON SCHEMAS FROM PUBLIC',
                rec.owner
              );
            END IF;

            -- Step (c): drop the temporary membership
            BEGIN
              EXECUTE format('REVOKE %I FROM %I', rec.owner, current_user);
            EXCEPTION WHEN OTHERS THEN
              -- ignore
            END;
          END LOOP;
        END $do$;

      $q$;

      -- run the hardening block inside the target DB
      PERFORM dblink_exec(rdb.datname, inner_sql);

      -- close the connection and log success
      PERFORM dblink_disconnect(rdb.datname);
      INSERT INTO tmp_public_hardening_log VALUES (rdb.datname, 'HARDEN', 'OK');

    EXCEPTION WHEN OTHERS THEN
      -- log failure and try to disconnect (if open)
      INSERT INTO tmp_public_hardening_log VALUES (rdb.datname, 'HARDEN', SQLERRM);
      BEGIN
        PERFORM dblink_disconnect(rdb.datname);
      EXCEPTION WHEN OTHERS THEN
        -- ignore
      END;
    END;
  END LOOP;
END $$;

-- Final report
SELECT database, step, outcome
FROM tmp_public_hardening_log
ORDER BY database, step;