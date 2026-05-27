CREATE ROLE sdbsecadmin WITH ENCRYPTED PASSWORD 'G7$^FeJLm5pe2025' LOGIN;


--GRANT CONNECT ON DATABASE postgres To sdbsecadmin;

grant connect on database postgres to sdbsecadmin;


--GRANT USAGE ON SCHEMA PG_CATALOG TO sdbsecadmin;  



--GRANT SELECT ON PG_CATALOG.PG_SETTINGS TO sdbsecadmin;  



--GRANT SELECT ON PG_CATALOG.PG_USER TO sdbsecadmin;  



--GRANT SELECT ON PG_CATALOG.PG_GROUP TO sdbsecadmin;  



--GRANT SELECT ON PG_CATALOG.PG_ROLES TO sdbsecadmin;  



--GRANT SELECT ON PG_CATALOG.PG_SHADOW TO sdbsecadmin;  



--GRANT SELECT ON PG_CATALOG.PG_CLASS TO sdbsecadmin;  



--GRANT SELECT ON PG_CATALOG.PG_STAT_ACTIVITY TO sdbsecadmin;  



--GRANT SELECT ON PG_CATALOG.PG_LOCKS TO sdbsecadmin;  



--GRANT SELECT ON PG_CATALOG.PG_DATABASE TO sdbsecadmin;  



--GRANT SELECT ON PG_CATALOG.PG_NAMESPACE TO sdbsecadmin;  



--GRANT SELECT ON PG_CATALOG.PG_TABLESPACE TO sdbsecadmin;  



--GRANT SELECT ON PG_CATALOG.PG_AUTHID to sdbsecadmin;  





--For PostgreSQL 10.x and up, we recommend to grant this privilege:  



GRANT PG_READ_ALL_SETTINGS to sdbsecadmin;  , ps_read_all_data,db_datareader