SELECT datname AS database,
       pg_catalog.pg_get_userbyid(datdba) AS owner
FROM pg_database
ORDER BY datname;