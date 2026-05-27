SELECT 
    table_name,
    COUNT(column_name) AS column_count
FROM 
    information_schema.columns
WHERE 
    table_schema = 'public' and table_name not like '%vw_%' and table_name not like '%_view%' and table_name not like '%google_%'
	and table_name not like '%hypopg_%'
GROUP BY 
    table_name
ORDER BY 
    table_name;



---------------------------


SELECT 
    table_name,
    COUNT(column_name) AS column_count
FROM 
    information_schema.columns
WHERE 
    table_schema = 'public'
GROUP BY 
    table_name
ORDER BY 
    table_name;




If you also want **table type** (table vs view):


SELECT 
    c.table_name,
    t.table_type,
    COUNT(c.column_name)    AS column_count
FROM 
    information_schema.columns c
JOIN 
    information_schema.tables t 
    ON c.table_name   = t.table_name 
    AND c.table_schema = t.table_schema
WHERE 
    c.table_schema = 'public'
GROUP BY 
    c.table_name, t.table_type
ORDER BY 
    t.table_type, c.table_name;




If you want **only user tables** (excluding views):


SELECT 
    c.table_name,
    COUNT(c.column_name)    AS column_count
FROM 
    information_schema.columns c
JOIN 
    information_schema.tables t 
    ON c.table_name    = t.table_name 
    AND c.table_schema = t.table_schema
WHERE 
    c.table_schema = 'public'
    AND t.table_type   = 'BASE TABLE'
GROUP BY 
    c.table_name
ORDER BY 
    column_count DESC;


> **Tip:** Change `ORDER BY column_count DESC` to `ORDER BY table_name` if you prefer alphabetical order instead of sorting by most columns first.