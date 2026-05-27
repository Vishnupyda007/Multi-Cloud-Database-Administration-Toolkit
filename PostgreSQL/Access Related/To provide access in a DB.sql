create role EDS_ETL_test with login password 'Edstest@2025';
grant connect on database ent_data_store to EDS_ETL_test;
GRANT CONNECT ON DATABASE ent_data_store TO "EDS_ETL_test";
GRANT USAGE ON SCHEMA eds_stg_prov TO "EDS_ETL_test";
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA eds_stg_prov TO "EDS_ETL_test"

ALTER DEFAULT PRIVILEGES IN SCHEMA eds_stg_prov GRANT SELECT, insert,update,delete ON TABLES TO "EDS_ETL_test";
