grant connect on database ent_data_store to UserName;  -- to grant connect to any database for a login.

GRANT USAGE ON SCHEMA SchemaName TO UserName;

If you want to grant SELECT on all tables in a schema:

GRANT SELECT ON ALL TABLES IN SCHEMA SchemaName TO username;



to grant select for a view or table:

GRANT select ON TABLE tableName IN SCHEMA Schemaname TO username;

GRANT select ON TABLE ViewName IN SCHEMA Schemaname TO username;



To grant select on specific column of table or view:

GRANT SELECT (column1, column2) ON view_name TO username;

GRANT Select (column_a) ON tableName TO username;



To revoke Access:

REVOKE select ON  TABLE tableName IN SCHEMA myschema FROM username;

REVOKE select ON  TABLE ViewName IN SCHEMA myschema FROM PUBLIC;



# In PostgreSQL, We cannot drop a role if it has access to objects in the database, hence we have to run below script :

> 
-- Remove all objects owned by the role/login
DROP OWNED BY LoginName;


then:

Drop role LoginName;

