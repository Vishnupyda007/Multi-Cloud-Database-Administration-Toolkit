SELECT
    datname AS database_name,
    ROUND(pg_database_size(datname) / 1024 / 1024 / 1024, 2) AS size_gb,
    pg_size_pretty(pg_database_size(datname)) AS size_pretty
FROM pg_database
WHERE datistemplate = false
ORDER BY pg_database_size(datname) DESC;

grant db_datareader,db_datawriter to "ats-4681-np-sa@cb0104074a-citnonprod-gc.iam";
grant "ats-4681-np-sa@cb0104074a-citnonprod-gc.iam" to postgres with admin option;
grant temp,connect on database "OneC_4681" to "ats-4681-np-sa@cb0104074a-citnonprod-gc.iam";
GRANT EXECUTE ON ALL ROUTINES IN SCHEMA public TO "ats-4681-np-sa@cb0104074a-citnonprod-gc.iam";


ALTER DEFAULT PRIVILEGES
FOR ROLE "OneC_4681","npgke-devops-serviceacc@cb0104074a-citnonprod-gc.iam"
--IN SCHEMA public
GRANT EXECUTE ON ROUTINES TO "ats-4681-np-sa@cb0104074a-citnonprod-gc.iam";
