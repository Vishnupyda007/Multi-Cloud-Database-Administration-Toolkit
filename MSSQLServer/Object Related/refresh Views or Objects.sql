sp_refreshview: Specifically updates the metadata for a non-schema-bound view.
Syntax: EXECUTE sp_refreshview N'schema_name.view_name';

sp_refreshsqlmodule: A more general procedure that can refresh views, stored procedures, and triggers.Syntax: 
EXECUTE sp_refreshsqlmodule N'schema_name.view_name'