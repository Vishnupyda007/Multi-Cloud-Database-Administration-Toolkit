-- Ensure dblink is available (Cloud SQL: requires cloudsqlsuperuser)
CREATE EXTENSION IF NOT EXISTS dblink;

-- Collect results here
DROP TABLE IF EXISTS tmp_public_audit;
CREATE TEMP TABLE tmp_public_audit(
  database text,
  section  text,
  info     text
);

DO $$
DECLARE
  -- Fallback host/IP if inet_server_addr() is NULL (e.g., socket connection)
  fallback_host text := '10.75.154.9';   -- e.g., '10.75.154.5' (private IP) or your public IP
  port          int  := 5432;
  usr           text := 'postgres';
  pwd           text := '8>z{&knxM\OyHud:';

  detected_host text;
  rdb record;
  conn_str text;
  inner_sql text;
BEGIN
  -- Prefer the live server IP; fallback to manual host if NULL
  SELECT COALESCE(host(inet_server_addr()), fallback_host) INTO detected_host;
  -- host(inet_server_addr()) returns the textual IP; inet_server_addr() is the server address for this session.
  -- (If you see NULL here, set 'fallback_host' above.)  -- Ref: inet_server_addr() docs
  -- Note: For Cloud SQL intra-instance connections, do not use localhost. Use the instance IP. 

  FOR rdb IN
    SELECT datname
    FROM pg_database
    WHERE datname NOT IN ('template0', 'cloudsqladmin')
  LOOP
    BEGIN
      conn_str := format('host=%s port=%s dbname=%s user=%s password=%s',
                         detected_host, port, rdb.datname, usr, pwd);

      -- Open named dblink connection per database
      PERFORM dblink_connect(rdb.datname, conn_str);

      -- Inner safety-check (same logic as before: A/B/C + D/E/F/G sections)
      inner_sql := $q$
        WITH
        params AS (
          SELECT current_database()::text AS dbname,
                 (SELECT datdba FROM pg_database WHERE datname = current_database()) AS db_owner_oid
        ),
        db_acl AS (
          SELECT (aclexplode(coalesce(d.datacl, acldefault('d', d.datdba)))).*
          FROM pg_database d
          JOIN params p ON p.dbname = d.datname
        ),
        db_public_has AS (
          SELECT
            bool_or(privilege_type = 'CONNECT' AND grantee = 0)                       AS pub_connect,
            bool_or((privilege_type IN ('TEMPORARY','TEMP')) AND grantee = 0)         AS pub_temp
          FROM db_acl
        ),
        db_explicit_connect_grantees AS (
          SELECT DISTINCT grantee
          FROM db_acl
          WHERE grantee <> 0 AND privilege_type = 'CONNECT'
        ),
        login_roles AS (
          SELECT r.oid, r.rolname
          FROM pg_roles r, params p
          WHERE r.rolcanlogin AND NOT r.rolsuper AND r.oid <> p.db_owner_oid
        ),
        at_risk_connect AS (
          SELECT lr.rolname AS role
          FROM login_roles lr
          CROSS JOIN params p
          CROSS JOIN db_public_has ph
          WHERE ph.pub_connect IS TRUE
            AND has_database_privilege(lr.oid, p.dbname, 'CONNECT') IS TRUE
            AND NOT EXISTS (
              SELECT 1
              FROM db_explicit_connect_grantees g
              WHERE pg_has_role(lr.oid, g.grantee, 'USAGE')
            )
        ),
        nsp AS (
          SELECT n.oid AS nsp_oid, n.nspname,
                 (aclexplode(coalesce(n.nspacl, acldefault('n', n.nspowner)))).*
          FROM pg_namespace n
          WHERE n.nspname = 'public'
        ),
        schema_public_has AS (
          SELECT
            bool_or(privilege_type = 'USAGE'  AND grantee = 0) AS pub_usage,
            bool_or(privilege_type = 'CREATE' AND grantee = 0) AS pub_create
          FROM nsp
        ),
        schema_explicit_usage_grantees AS (
          SELECT DISTINCT grantee
          FROM nsp
          WHERE grantee <> 0 AND privilege_type = 'USAGE'
        ),
        schema_explicit_create_grantees AS (
          SELECT DISTINCT grantee
          FROM nsp
          WHERE grantee <> 0 AND privilege_type = 'CREATE'
        ),
        at_risk_schema_usage AS (
          SELECT lr.rolname AS role
          FROM login_roles lr
          CROSS JOIN schema_public_has ph
          WHERE ph.pub_usage IS TRUE
            AND has_schema_privilege(lr.oid, 'public', 'USAGE') IS TRUE
            AND NOT EXISTS (
              SELECT 1
              FROM schema_explicit_usage_grantees g
              WHERE pg_has_role(lr.oid, g.grantee, 'USAGE')
            )
        ),
        at_risk_schema_create AS (
          SELECT lr.rolname AS role
          FROM login_roles lr
          CROSS JOIN schema_public_has ph
          WHERE ph.pub_create IS TRUE
            AND has_schema_privilege(lr.oid, 'public', 'CREATE') IS TRUE
            AND NOT EXISTS (
              SELECT 1
              FROM schema_explicit_create_grantees g
              WHERE pg_has_role(lr.oid, g.grantee, 'USAGE')
            )
        ),
        defacl AS (
          SELECT
            da.defaclrole,
            pg_get_userbyid(da.defaclrole) AS owner,
            CASE da.defaclobjtype
              WHEN 'r' THEN 'TABLES'
              WHEN 'S' THEN 'SEQUENCES'
              WHEN 'f' THEN 'FUNCTIONS'
              WHEN 'T' THEN 'TYPES'
              WHEN 'n' THEN 'SCHEMAS'
              ELSE da.defaclobjtype::text
            END AS objtype,
            da.defaclnamespace,
            n.nspname AS schema_name,
            (aclexplode(coalesce(da.defaclacl, acldefault(da.defaclobjtype, da.defaclrole)))).*
          FROM pg_default_acl da
          LEFT JOIN pg_namespace n ON n.oid = da.defaclnamespace
        ),
        defacl_public_all AS (
          SELECT owner, objtype, coalesce(schema_name, '<all_schemas>') AS scope,
                 privilege_type, is_grantable
          FROM defacl
          WHERE grantee = 0
        ),
        defacl_public_in_public_schema AS (
          SELECT owner, objtype, 'public'::text AS scope,
                 privilege_type, is_grantable
          FROM defacl
          WHERE grantee = 0 AND schema_name = 'public'
        ),
        defacl_nonpublic_all AS (
          SELECT owner, objtype, coalesce(schema_name, '<all_schemas>') AS scope,
                 pg_get_userbyid(grantee) AS grantee_name,
                 privilege_type, is_grantable
          FROM defacl
          WHERE grantee <> 0
        ),
        public_schema_acl_public AS (
          SELECT privilege_type, is_grantable
          FROM nsp
          WHERE grantee = 0
        )
        SELECT 'A. Roles that would lose DB CONNECT' AS section, role AS info
        FROM at_risk_connect
        UNION ALL
        SELECT 'B. Roles that would lose USAGE on schema public', role
        FROM at_risk_schema_usage
        UNION ALL
        SELECT 'C. Roles that would lose CREATE on schema public', role
        FROM at_risk_schema_create
        UNION ALL
        SELECT 'D. Default privileges → PUBLIC',
               format('owner=%s, objtype=%s, scope=%s, priv=%s, grantable=%s',
                      owner, objtype, scope, privilege_type, is_grantable)::text
        FROM defacl_public_all
        UNION ALL
        SELECT 'E. Default privileges IN SCHEMA public → PUBLIC',
               format('owner=%s, objtype=%s, scope=%s, priv=%s, grantable=%s',
                      owner, objtype, scope, privilege_type, is_grantable)::text
        FROM defacl_public_in_public_schema
        UNION ALL
        SELECT 'F. Default privileges → NON-PUBLIC role',
               format('owner=%s, objtype=%s, scope=%s, grantee=%s, priv=%s, grantable=%s',
                      owner, objtype, scope, grantee_name, privilege_type, is_grantable)::text
        FROM defacl_nonpublic_all
        UNION ALL
        SELECT 'G. Schema public current grants → PUBLIC',
               format('priv=%s, grantable=%s', privilege_type, is_grantable)::text
        FROM public_schema_acl_public
        ORDER BY 1, 2
      $q$;

      INSERT INTO tmp_public_audit(database, section, info)
      SELECT rdb.datname, t.section, t.info
      FROM dblink(rdb.datname, inner_sql) AS t(section text, info text);

      PERFORM dblink_disconnect(rdb.datname);

    EXCEPTION WHEN OTHERS THEN
      -- Record the failure and continue with next DB
      INSERT INTO tmp_public_audit(database, section, info)
      VALUES (rdb.datname, 'Z. Skipped (connect/query failed)', SQLERRM);

      -- Try to clean up the connection if one was opened
      BEGIN
        PERFORM dblink_disconnect(rdb.datname);
      EXCEPTION WHEN OTHERS THEN
        -- ignore
      END;
    END;
  END LOOP;
END $$;

-- Final report
SELECT database, section, info
FROM tmp_public_audit where section='D. Default privileges → PUBLIC'
ORDER BY database, section, info, section like 'D%';