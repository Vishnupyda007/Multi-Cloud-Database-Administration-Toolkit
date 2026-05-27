amcheck,dblink
pg_buffercache
pg_cron
pg_stat_statements
pgstattuple


ALTER DEFAULT PRIVILEGES FOR ROLE postgres
GRANT EXECUTE ON FUNCTIONS TO "DBMaintenanceUser";

GRANT CONNECT ON DATABASE postgres TO "ITESVMadmin";

GRANT CONNECT ON DATABASE postgres TO "DBMaintenanceUser";

ALTER DEFAULT PRIVILEGES FOR ROLE postgres
GRANT DELETE, INSERT, SELECT, TRUNCATE, UPDATE ON TABLES TO "DBMaintenanceUser";