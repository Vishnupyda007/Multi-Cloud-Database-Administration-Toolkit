SELECT 
    n.nspname AS schema_name,
    c.relname AS object_name,
    c.relkind AS object_type,
    pg_get_userbyid(c.relowner) AS owner
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
--WHERE pg_get_userbyid(c.relowner)in ('OneC_4652','csagenticaiapp-smp-4652-np-sa@cb0104074a-citnonprod-gc.iam','npgke-devops-serviceacc@cb0104074a-citnonprod-gc.iam')
ORDER BY schema_name, object_type, object_name;


