You can query the information_schema.routines view or the pg_catalog.pg_proc system table. 
Using information_schema.routines (SQL Standard approach):
sql
SELECT
    routine_name AS name,
    routine_type AS type,
    data_type AS return_type
FROM
    information_schema.routines
WHERE
    routine_schema = 'public'
ORDER BY
    name;
This query uses the standard SQL information_schema view, which works across different database systems. The routine_type column explicitly indicates whether an entry is a 'FUNCTION' or a 'PROCEDURE'. 
Devart
Devart
 +1
Using pg_catalog.pg_proc (PostgreSQL specific approach):
sql
SELECT
    p.proname AS name,
    CASE p.prokind
        WHEN 'p' THEN 'PROCEDURE'
        ELSE 'FUNCTION'
    END AS type,
    pg_get_function_arguments(p.oid) AS arguments
FROM
    pg_catalog.pg_proc p
JOIN
    pg_catalog.pg_namespace n ON n.oid = p.pronamespace
WHERE
    n.nspname = 'public'
ORDER BY
    name;
This query provides more detailed information using PostgreSQL-specific functions and the prokind column to differentiate between functions ('f'), procedures ('p'), aggregate functions ('a'), and window functions ('w'). 
Using the psql Command-Line Tool
If you have access to the psql command-line interface, the \df command and its variations are a simple way to list functions and procedures. 
Devart
Devart
List all functions and procedures in the public schema:
bash
\df public.*
List all functions and procedures in the current database with more details:
bash
\df+
This command provides details such as function names, accepted arguments, return types, and more