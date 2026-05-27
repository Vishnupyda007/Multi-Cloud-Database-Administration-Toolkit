
SELECT n.nspname AS schema, pg_get_userbyid(n.nspowner) AS owner
FROM pg_namespace n
