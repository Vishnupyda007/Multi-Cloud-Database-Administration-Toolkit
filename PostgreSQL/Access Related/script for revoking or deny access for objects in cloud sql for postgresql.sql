Below is a practical, production-friendly way to **revoke (i.e., deny) access** to objects in **Cloud SQL for PostgreSQL**—covering **tables, views, sequences, functions, and schemas**, plus **default privileges** so future objects don’t get auto-granted.

You can use either **pure SQL** (run via `psql`), or a **Bash + psql** script that auto-generates `REVOKE` statements from metadata. I’ve included both.

***

## 1) Quick SQL snippets (targeted revokes)

> Replace `mydb`, `myschema`, and `target_role` with your actual values.

### Revoke on schema

```sql
-- Connect to target database
\c mydb

BEGIN;

-- Remove usage and create from schema for a role
REVOKE USAGE ON SCHEMA myschema FROM target_role;
REVOKE CREATE ON SCHEMA myschema FROM target_role;

COMMIT;
```

### Revoke on tables & views

```sql
BEGIN;

-- Revoke ALL privileges (SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER)
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA myschema FROM target_role;

COMMIT;
```

### Revoke on sequences

```sql
BEGIN;

-- Revoke USAGE/SELECT/UPDATE etc. on sequences
REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA myschema FROM target_role;

COMMIT;
```

### Revoke on functions

```sql
BEGIN;

-- Revoke EXECUTE on functions
REVOKE ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA myschema FROM target_role;

COMMIT;
```

### Revoke default privileges (prevent future grants)

> Run this as the **object owner** (or the role that creates objects).

```sql
BEGIN;

-- Future tables/views in myschema won't grant anything to target_role
ALTER DEFAULT PRIVILEGES IN SCHEMA myschema
  REVOKE ALL ON TABLES FROM target_role;

-- Future sequences
ALTER DEFAULT PRIVILEGES IN SCHEMA myschema
  REVOKE ALL ON SEQUENCES FROM target_role;

-- Future functions
ALTER DEFAULT PRIVILEGES IN SCHEMA myschema
  REVOKE ALL ON FUNCTIONS FROM target_role;

-- Future types
ALTER DEFAULT PRIVILEGES IN SCHEMA myschema
  REVOKE ALL ON TYPES FROM target_role;

COMMIT;
```

> **Note:** `ALTER DEFAULT PRIVILEGES` is per-object *owner*. If multiple owners create objects, apply it for each owner or centralize object creation.

***

## 2) Robust Bash + psql script (auto-generates revoke statements)

This script:

*   Revokes privileges across all object types in a schema for a given role
*   Logs what it does
*   Supports a **dry run** mode

> Save as `revoke_access.sh`, make executable: `chmod +x revoke_access.sh`, run:  
> `./revoke_access.sh "host" "port" "db" "user" "schema" "role" [dry-run]`

```bash
#!/usr/bin/env bash
# Usage: ./revoke_access.sh HOST PORT DBNAME ADMIN_USER SCHEMA TARGET_ROLE [dry-run]
set -euo pipefail

HOST="${1:-127.0.0.1}"
PORT="${2:-5432}"
DB="${3:-mydb}"
ADMIN_USER="${4:-postgres}"
SCHEMA="${5:-public}"
TARGET_ROLE="${6:-some_role}"
DRY_RUN="${7:-}"

PSQL="psql 'host=${HOST} port=${PORT} dbname=${DB} user=${ADMIN_USER} sslmode=require' -v ON_ERROR_STOP=1 --no-align --tuples-only"

echo "==> Database: ${DB}, Schema: ${SCHEMA}, Target role: ${TARGET_ROLE}"
echo "==> Dry-run: ${DRY_RUN:+yes}${DRY_RUN:-no}"

# 1) Schema-level revoke
SCHEMA_SQL=$(cat <<SQL
SELECT 'REVOKE USAGE ON SCHEMA '||quote_ident('${SCHEMA}')||' FROM '||quote_ident('${TARGET_ROLE}')||';'
UNION ALL
SELECT 'REVOKE CREATE ON SCHEMA '||quote_ident('${SCHEMA}')||' FROM '||quote_ident('${TARGET_ROLE}')||';';
SQL
)

# 2) Tables & views
TABLE_SQL=$(cat <<SQL
SELECT 'REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA '||quote_ident('${SCHEMA}')||' FROM '||quote_ident('${TARGET_ROLE}')||';';
SQL
)

# 3) Sequences
SEQ_SQL=$(cat <<SQL
SELECT 'REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA '||quote_ident('${SCHEMA}')||' FROM '||quote_ident('${TARGET_ROLE}')||';';
SQL
)

# 4) Functions (explicit per function is safer across versions)
FUNC_SQL=$(cat <<'SQL'
WITH funcs AS (
  SELECT n.nspname AS schema_name,
         p.proname AS func_name,
         pg_get_function_identity_arguments(p.oid) AS args
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = :'schema'
)
SELECT 'REVOKE ALL PRIVILEGES ON FUNCTION '
       ||quote_ident(schema_name)||'.'||quote_ident(func_name)
       ||'('||args||') FROM '||quote_ident(:'role')||';'
FROM funcs
ORDER BY 1;
SQL
)

# 5) Default privileges (must be run as each object owner; here we run as ADMIN_USER)
DEFPRIV_SQL=$(cat <<SQL
SELECT 'ALTER DEFAULT PRIVILEGES IN SCHEMA '||quote_ident('${SCHEMA}')||
       ' REVOKE ALL ON TABLES FROM '||quote_ident('${TARGET_ROLE}')||';'
UNION ALL
SELECT 'ALTER DEFAULT PRIVILEGES IN SCHEMA '||quote_ident('${SCHEMA}')||
       ' REVOKE ALL ON SEQUENCES FROM '||quote_ident('${TARGET_ROLE}')||';'
UNION ALL
SELECT 'ALTER DEFAULT PRIVILEGES IN SCHEMA '||quote_ident('${SCHEMA}')||
       ' REVOKE ALL ON FUNCTIONS FROM '||quote_ident('${TARGET_ROLE}')||';'
UNION ALL
SELECT 'ALTER DEFAULT PRIVILEGES IN SCHEMA '||quote_ident('${SCHEMA}')||
       ' REVOKE ALL ON TYPES FROM '||quote_ident('${TARGET_ROLE}')||';';
SQL
)

echo "==> Generating statements..."
{
  echo "BEGIN;"
  ${PSQL} -c "${SCHEMA_SQL}"
  ${PSQL} -c "${TABLE_SQL}"
  ${PSQL} -c "${SEQ_SQL}"
  # Functions: use variables for schema and role
  ${PSQL} --set=schema="${SCHEMA}" --set=role="${TARGET_ROLE}" -c "${FUNC_SQL}"
  ${PSQL} -c "${DEFPRIV_SQL}"
  echo "COMMIT;"
} > /tmp/revoke_${DB}_${SCHEMA}_${TARGET_ROLE}.sql

echo "==> Plan written to /tmp/revoke_${DB}_${SCHEMA}_${TARGET_ROLE}.sql"
if [[ -n "${DRY_RUN}" ]]; then
  echo "==> Dry run mode: not executing. Review the SQL file above."
  exit 0
fi

echo "==> Executing..."
psql "host=${HOST} port=${PORT} dbname=${DB} user=${ADMIN_USER} sslmode=require" -v ON_ERROR_STOP=1 -f /tmp/revoke_${DB}_${SCHEMA}_${TARGET_ROLE}.sql

echo "==> Done."
```

**Notes:**

*   If you get errors on function revokes, it’s usually due to overloaded functions. The script uses **identity arguments** to target exact signatures.
*   In Cloud SQL, you typically don’t have `SUPERUSER`, but you don’t need it for `REVOKE`. You **do** need to be the owner of the object (or a role with `GRANT OPTION` on that object). Otherwise, run as the object owner or reassign owner with care.
*   To completely block schema visibility, revoking `USAGE` on the schema is key.

***

## 3) Common patterns you may need

### Revoke connect on database (prevent login to a specific DB)

```sql
REVOKE CONNECT ON DATABASE mydb FROM target_role;
```

### Remove role from group roles

```sql
-- If access is inherited via role membership
REVOKE target_role FROM parent_role;  -- remove role membership
```

### Remove public (implicit) privileges

```sql
-- Sometimes PUBLIC has privileges; remove them
REVOKE ALL ON SCHEMA myschema FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA myschema FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA myschema FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA myschema FROM PUBLIC;
```

***

## 4) Safety checklist (so you don’t lock out apps unintentionally)

*   ✅ Identify **which role(s)** actually have privileges (via `information_schema.table_privileges`, `information_schema.usage_privileges`, `pg_proc` owners).
*   ✅ Do a **dry run** first and capture exact statements.
*   ✅ Revoke in **lower environments** first.
*   ✅ Coordinate with **object owners** for `ALTER DEFAULT PRIVILEGES`.
*   ✅ If apps use `PUBLIC` privileges, ensure they have explicit grants before you revoke from `PUBLIC`.

***

If you share your **schema name(s)** and the **role(s)** you want to restrict, I can tailor the script to your environment (including handling multiple schemas, or excluding specific objects that should retain access).
