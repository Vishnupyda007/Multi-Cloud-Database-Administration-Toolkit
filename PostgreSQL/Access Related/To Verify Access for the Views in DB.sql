-- =====================================================================
-- Script: Check Role/User Access to Views (Full & Column Level)
-- =====================================================================

-- -------------------------------------------------------
-- 1. VIEW LEVEL ACCESS (Full View Access)
-- -------------------------------------------------------
SELECT 
    grantee                         AS role_or_user,
    table_schema                    AS schema_name,
    table_name                      AS view_name,
    privilege_type                  AS access_type,
    is_grantable                    AS can_grant_to_others,
    'FULL VIEW ACCESS'              AS access_level
FROM 
    information_schema.role_table_grants
WHERE 
    table_schema = 'public'  AND grantee = 'your_role_name'   -- exact role/user name, case-sensitive            -- change schema if needed
    AND table_name IN (
        SELECT table_name 
        FROM information_schema.views 
        WHERE table_schema = 'public'               -- change schema if needed
    )
-- AND grantee = 'your_role_name'                   -- uncomment to filter specific role
ORDER BY 
    grantee, table_name, privilege_type;


-- -------------------------------------------------------
-- 2. COLUMN LEVEL ACCESS (Column Level Privileges on Views)
-- -------------------------------------------------------
SELECT 
    grantee                         AS role_or_user,
    table_schema                    AS schema_name,
    table_name                      AS view_name,
    column_name,
    privilege_type                  AS access_type,
    is_grantable                    AS can_grant_to_others,
    'COLUMN LEVEL ACCESS'           AS access_level
FROM 
    information_schema.role_column_grants
WHERE 
    table_schema = 'public'                         -- change schema if needed
    AND table_name IN (
        SELECT table_name 
        FROM information_schema.views 
        WHERE table_schema = 'public'               -- change schema if needed
    )
-- AND grantee = 'your_role_name'                   -- uncomment to filter specific role
ORDER BY 
    grantee, table_name, column_name, privilege_type;


-- -------------------------------------------------------
-- 3. COMBINED REPORT (Full + Column Level in One Result)
-- -------------------------------------------------------
SELECT 
    grantee                         AS role_or_user,
    table_schema                    AS schema_name,
    table_name                      AS view_name,
    NULL                            AS column_name,
    privilege_type                  AS access_type,
    is_grantable                    AS can_grant_to_others,
    'FULL VIEW ACCESS'              AS access_level
FROM 
    information_schema.role_table_grants
WHERE 
    table_schema = 'public'
    AND table_name IN (
        SELECT table_name 
        FROM information_schema.views 
        WHERE table_schema = 'public'
    )

UNION ALL

SELECT 
    grantee                         AS role_or_user,
    table_schema                    AS schema_name,
    table_name                      AS view_name,
    column_name,
    privilege_type                  AS access_type,
    is_grantable                    AS can_grant_to_others,
    'COLUMN LEVEL ACCESS'           AS access_level
FROM 
    information_schema.role_column_grants
WHERE 
    table_schema = 'public'
    AND table_name IN (
        SELECT table_name 
        FROM information_schema.views 
        WHERE table_schema = 'public'
    )

ORDER BY 
    role_or_user, view_name, access_level, column_name;


-- -------------------------------------------------------
-- 4. SUMMARY — Count of Views Each Role Has Access To
-- -------------------------------------------------------
SELECT 
    grantee                         AS role_or_user,
    COUNT(DISTINCT table_name)      AS total_views_accessible,
    STRING_AGG(DISTINCT privilege_type, ', ')  AS access_types
FROM 
    information_schema.role_table_grants
WHERE 
    table_schema = 'public'
    AND table_name IN (
        SELECT table_name 
        FROM information_schema.views 
        WHERE table_schema = 'public'
    )
GROUP BY 
    grantee
ORDER BY 
    grantee;