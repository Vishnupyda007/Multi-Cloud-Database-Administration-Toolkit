CREATE ROLE db_datareader WITH
	NOLOGIN
	NOSUPERUSER
	NOCREATEDB
	NOCREATEROLE
	INHERIT
	NOREPLICATION
	NOBYPASSRLS
	CONNECTION LIMIT -1;

GRANT db_datareader TO postgres WITH ADMIN OPTION;



CREATE ROLE db_datawriter WITH
	NOLOGIN
	NOSUPERUSER
	NOCREATEDB
	NOCREATEROLE
	INHERIT
	NOREPLICATION
	NOBYPASSRLS
	CONNECTION LIMIT -1;

GRANT db_datawriter TO postgres WITH ADMIN OPTION;



CREATE ROLE db_owner WITH
	NOLOGIN
	NOSUPERUSER
	NOCREATEDB
	NOCREATEROLE
	INHERIT
	NOREPLICATION
	NOBYPASSRLS
	CONNECTION LIMIT -1;

GRANT db_owner TO postgres WITH ADMIN OPTION;


CREATE ROLE "DBReaderTool" WITH
	NOLOGIN
	NOSUPERUSER
	CREATEDB
	CREATEROLE
	INHERIT
	NOREPLICATION
	NOBYPASSRLS
	CONNECTION LIMIT -1;

GRANT "DBReaderTool" TO postgres WITH ADMIN OPTION;



CREATE ROLE "DBMaintenanceUser" WITH
	LOGIN
	NOSUPERUSER
	NOCREATEDB
	NOCREATEROLE
	INHERIT
	NOREPLICATION
	NOBYPASSRLS
	CONNECTION LIMIT -1
	PASSWORD 'xxxxxx';

GRANT pg_maintain, pg_read_all_stats, pg_stat_scan_tables TO "DBMaintenanceUser";
COMMENT ON ROLE "DBMaintenanceUser" IS 'DBA team maintenance User';


GRANT "DBMaintenanceUser" TO postgres WITH ADMIN OPTION;



create role "ITESVMadmin" with login password 'ITEsvm@2026';
GRANT pg_read_all_data TO "ITESVMadmin";
grant db_datareader to "ITESVMadmin";  
grant pg_read_all_settings to "ITESVMadmin";


CREATE EXTENSION amcheck
    SCHEMA "DBAdmin"
    VERSION "1.4";


CREATE EXTENSION pgstattuple
    SCHEMA "DBAdmin"
    VERSION "1.5";


CREATE EXTENSION vector
    SCHEMA public
    VERSION "0.8.1";	


CREATE EXTENSION btree_gin
    SCHEMA public	;


CREATE EXTENSION btree_gist
    SCHEMA public	;	


CREATE EXTENSION citext
    SCHEMA public	;

CREATE EXTENSION dblink
    SCHEMA public	;	


CREATE EXTENSION pgcrypto
    SCHEMA public	;	


CREATE EXTENSION postgres_fdw
    SCHEMA public	;	
	