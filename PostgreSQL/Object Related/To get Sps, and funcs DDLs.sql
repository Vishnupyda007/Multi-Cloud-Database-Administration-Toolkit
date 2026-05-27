SELECT n.nspname AS schema_name,
       p.proname AS function_name,
       pg_get_functiondef(p.oid) AS source_code
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'  -- change schema if needed
ORDER BY function_name;


--

SELECT pg_get_functiondef(p.oid) AS source_code FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace WHERE  n.nspname = 'public';--p.proname = 'your_function_name'AND



-------------------------------

-- ============================================================
-- FUNCTION & PROCEDURE DDLs EXTRACTOR
-- Covers: functions (f), procedures (p)
-- Excludes: aggregates (a), window functions (w),
--           and any routines owned by installed extensions
-- ============================================================

SELECT
  p.proname                    AS routine_name,
  CASE p.prokind
    WHEN 'f' THEN 'FUNCTION'
    WHEN 'p' THEN 'PROCEDURE'
  END                          AS routine_type,
  pg_get_functiondef(p.oid)    AS ddl
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'              -- change schema here if needed
  AND p.prokind NOT IN ('a', 'w')       -- skip aggregates & window functions
  AND NOT EXISTS (                      -- skip extension-owned routines
    SELECT 1
    FROM pg_depend d
    JOIN pg_extension ext ON ext.oid = d.refobjid
    WHERE d.objid = p.oid
      AND d.deptype = 'e'
  )
ORDER BY p.prokind, p.proname;