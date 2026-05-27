SELECT grantee, privilege_type, table_schema, table_name
FROM information_schema.role_table_grants
WHERE table_schema = 'dbotest'
  AND grantee IN ('db_datareader','db_datawriter')
ORDER BY table_name, grantee;