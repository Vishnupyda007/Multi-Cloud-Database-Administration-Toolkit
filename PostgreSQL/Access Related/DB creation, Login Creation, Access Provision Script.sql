
CREATE DATABASE my_database
  WITH OWNER = my_user
       ENCODING = 'UTF8'
       TEMPLATE = template1;

create role EDS_ETL_test with login password 'Edstest@2025';
grant connect on database ent_data_store to EDS_ETL_test;


--To create IAM Role
create role "csagenticaiapp-scd-4653-np-sa@cb0104074a-citnonprod-gc.iam" with login;

---note: we dont need to provide usage on schema for logins if they required access on specified object in a schema. we can directly provide access to schemaname.objectName for a login.

GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_user;
 

GRANT CONNECT ON DATABASE db_name TO "USER_EMAIL"; --only if a UserName is in case-sensitive
GRANT USAGE ON SCHEMA public TO "USER_EMAIL";
GRANT ALL ON ALL TABLES IN SCHEMA public TO "USER_EMAIL";
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO "USER_EMAIL";



GRANT CONNECT ON DATABASE db_name TO "USER_EMAIL";
GRANT USAGE ON SCHEMA public TO "USER_EMAIL";
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO "USER_EMA


create role EDS_ETL_test with login password 'Edstest@2025';
grant connect on database ent_data_store to EDS_ETL_test;


CREATE DATABASE ent_data_store OWNER postgres;
CREATE DATABASE OneC_4652 OWNER postgres;
CREATE DATABASE OneC_4653 OWNER postgres;

create role OneC_4652 with login password '1C4652@nonprod';
grant connect on database OneC_4652 to OneC_4652


If you want to grant SELECT on all tables in a schema:

GRANT SELECT ON ALL TABLES IN SCHEMA public TO username;

If you want to grant future tables too:

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO username;

