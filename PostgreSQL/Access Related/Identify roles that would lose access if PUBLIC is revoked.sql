-- =======================================================================================
-- SAFETY CHECK: Identify roles that would lose access if PUBLIC is revoked
--   A) Database-level CONNECT
--   B) Schema-level USAGE on schema "public"
--   C) Schema-level CREATE on schema "public"
-- Notes:
--   * Evaluates explicit grants (direct or via group roles) vs PUBLIC.
--   * Excludes superusers and the database owner.
--   * Uses current_database() for the DB target.
--   * Uses default ACLs if explicit ACLs are NULL (more robust).
-- =======================================================================================

WITH
-- ---------- Common params ----------
params AS (
  SELECT
    current_database()::text AS dbname,
    (SELECT datdba FROM pg_database WHERE datname = current_database()) AS db_owner_oid
),

-- ---------- DB ACL exploded (PUBLIC and others) ----------
db_acl AS (
  SELECT (aclexplode(coalesce(d.datacl, acldefault('d', d.datdba)))).*
  FROM pg_database d
  JOIN params p ON p.dbname = d.datname
  -- aclexplode returns: grantor oid, grantee oid (0 = PUBLIC), privilege_type text, is_grantable bool
),

-- ---------- Does PUBLIC currently have CONNECT/TEMP on this DB? ----------
db_public_has AS (
  SELECT
    bool_or(privilege_type = 'CONNECT' AND grantee = 0) AS pub_connect,
    bool_or((privilege_type IN ('TEMPORARY','TEMP')) AND grantee = 0) AS pub_temp
  FROM db_acl
),

-- ---------- Explicit (non-PUBLIC) CONNECT grantees on this DB ----------
db_explicit_connect_grantees AS (
  SELECT DISTINCT grantee
  FROM db_acl
  WHERE grantee <> 0 AND privilege_type = 'CONNECT'
),

-- ---------- Candidate LOGIN roles we care about ----------
login_roles AS (
  SELECT r.oid, r.rolname
  FROM pg_roles r, params p
  WHERE r.rolcanlogin
    AND NOT r.rolsuper
    AND r.oid <> p.db_owner_oid
),

-- ---------- A) Roles that would lose DB CONNECT if PUBLIC CONNECT is removed ----------
at_risk_connect AS (
  SELECT lr.rolname AS role
  FROM login_roles lr
  CROSS JOIN params p
  CROSS JOIN db_public_has ph
  WHERE
    ph.pub_connect IS TRUE                         -- PUBLIC currently provides CONNECT
    AND has_database_privilege(lr.oid, p.dbname, 'CONNECT') IS TRUE
    -- but they do NOT have an explicit or inherited CONNECT grant (excluding PUBLIC):
    AND NOT EXISTS (
      SELECT 1
      FROM db_explicit_connect_grantees g
      WHERE pg_has_role(lr.oid, g.grantee, 'USAGE')   -- direct or inherited membership in a grantee role
    )
),

-- ---------- Schema ACL exploded for schema "public" ----------
nsp AS (
  SELECT n.oid AS nsp_oid, n.nspname, (aclexplode(coalesce(n.nspacl, acldefault('n', n.nspowner)))).*
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

-- ---------- B) Roles that would lose USAGE on schema public ----------
at_risk_schema_usage AS (
  SELECT lr.rolname AS role
  FROM login_roles lr
  CROSS JOIN schema_public_has ph
  WHERE
    ph.pub_usage IS TRUE
    AND has_schema_privilege(lr.oid, 'public', 'USAGE') IS TRUE
    AND NOT EXISTS (
      SELECT 1
      FROM schema_explicit_usage_grantees g
      WHERE pg_has_role(lr.oid, g.grantee, 'USAGE')
    )
),

-- ---------- C) Roles that would lose CREATE on schema public ----------
at_risk_schema_create AS (
  SELECT lr.rolname AS role
  FROM login_roles lr
  CROSS JOIN schema_public_has ph
  WHERE
    ph.pub_create IS TRUE
    AND has_schema_privilege(lr.oid, 'public', 'CREATE') IS TRUE
    AND NOT EXISTS (
      SELECT 1
      FROM schema_explicit_create_grantees g
      WHERE pg_has_role(lr.oid, g.grantee, 'USAGE')
    )
)

-- ---------- Output (single ORDER BY after the UNION ALL) ----------
SELECT 'A. Roles that would lose DB CONNECT' AS section, role
FROM at_risk_connect
UNION ALL
SELECT 'B. Roles that would lose USAGE on schema public', role
FROM at_risk_schema_usage
UNION ALL
SELECT 'C. Roles that would lose CREATE on schema public', role
FROM at_risk_schema_create
ORDER BY section, role;