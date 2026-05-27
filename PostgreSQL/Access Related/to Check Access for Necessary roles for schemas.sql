
WITH user_schemas AS (
  SELECT nspname
  FROM pg_namespace
  WHERE nspname !~ '^pg_' AND nspname <> 'information_schema'
)
SELECT
  s.nspname AS schema,
  'db_datareader' AS role,
  has_schema_privilege('db_datareader', s.nspname, 'USAGE')  AS usage,
  has_schema_privilege('db_datareader', s.nspname, 'CREATE') AS create
FROM user_schemas s
UNION ALL
SELECT
  s.nspname AS schema,
  'db_datawriter' AS role,
  has_schema_privilege('db_datawriter', s.nspname, 'USAGE')  AS usage,
  has_schema_privilege('db_datawriter', s.nspname, 'CREATE') AS create
FROM user_schemas s
ORDER BY schema, role;
