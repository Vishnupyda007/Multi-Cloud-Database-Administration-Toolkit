-- ============================================================
-- TYPE DDLs EXTRACTOR (excludes extension-owned types)
-- Covers: enums, composite types, domains, range types, table types
-- ============================================================

-- ENUM TYPES
SELECT
  'CREATE TYPE ' || n.nspname || '.' || t.typname || ' AS ENUM (' ||
  string_agg(quote_literal(e.enumlabel), ', ' ORDER BY e.enumsortorder) ||
  ');' AS ddl
FROM pg_type t
JOIN pg_namespace n ON n.oid = t.typnamespace
JOIN pg_enum e ON e.enumtypid = t.oid
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND NOT EXISTS (
    SELECT 1 FROM pg_depend d
    JOIN pg_extension ext ON ext.oid = d.refobjid
    WHERE d.objid = t.oid AND d.deptype = 'e'
  )
GROUP BY n.nspname, t.typname

UNION ALL

-- COMPOSITE TYPES (standalone, not backed by a table)
SELECT
  'CREATE TYPE ' || n.nspname || '.' || t.typname || ' AS (' ||
  string_agg(a.attname || ' ' || pg_catalog.format_type(a.atttypid, a.atttypmod), ', ' ORDER BY a.attnum) ||
  ');' AS ddl
FROM pg_type t
JOIN pg_namespace n ON n.oid = t.typnamespace
JOIN pg_class c ON c.oid = t.typrelid
JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum > 0
WHERE t.typtype = 'c'
  AND c.relkind = 'c'
  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND NOT EXISTS (
    SELECT 1 FROM pg_depend d
    JOIN pg_extension ext ON ext.oid = d.refobjid
    WHERE d.objid = t.oid AND d.deptype = 'e'
  )
GROUP BY n.nspname, t.typname

UNION ALL

-- TABLE TYPES (row types implicitly created for each table/view/materialized view)
SELECT
  '-- Row type for ' ||
  CASE c.relkind
    WHEN 'r' THEN 'table'
    WHEN 'v' THEN 'view'
    WHEN 'm' THEN 'materialized view'
    WHEN 'f' THEN 'foreign table'
  END ||
  E'\nCREATE TYPE ' || n.nspname || '.' || t.typname || ' AS (' ||
  string_agg(a.attname || ' ' || pg_catalog.format_type(a.atttypid, a.atttypmod), ', ' ORDER BY a.attnum) ||
  ');' AS ddl
FROM pg_type t
JOIN pg_namespace n ON n.oid = t.typnamespace
JOIN pg_class c ON c.oid = t.typrelid
JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum > 0
WHERE t.typtype = 'c'
  AND c.relkind IN ('r', 'v', 'm', 'f')
  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND NOT EXISTS (
    SELECT 1 FROM pg_depend d
    JOIN pg_extension ext ON ext.oid = d.refobjid
    WHERE d.objid = t.oid AND d.deptype = 'e'
  )
GROUP BY n.nspname, t.typname, c.relkind

UNION ALL

-- DOMAIN TYPES
SELECT
  'CREATE DOMAIN ' || n.nspname || '.' || t.typname || ' AS ' ||
  pg_catalog.format_type(t.typbasetype, t.typtypmod) ||
  CASE WHEN t.typnotnull THEN ' NOT NULL' ELSE '' END ||
  CASE WHEN t.typdefault IS NOT NULL THEN ' DEFAULT ' || t.typdefault ELSE '' END ||
  ';' AS ddl
FROM pg_type t
JOIN pg_namespace n ON n.oid = t.typnamespace
WHERE t.typtype = 'd'
  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND NOT EXISTS (
    SELECT 1 FROM pg_depend d
    JOIN pg_extension ext ON ext.oid = d.refobjid
    WHERE d.objid = t.oid AND d.deptype = 'e'
  )

UNION ALL

-- RANGE TYPES
SELECT
  'CREATE TYPE ' || n.nspname || '.' || t.typname || ' AS RANGE (SUBTYPE = ' ||
  pg_catalog.format_type(r.rngsubtype, NULL) ||
  CASE WHEN r.rngsubopc <> 0 THEN ', SUBTYPE_OPCLASS = ' || op.opcname ELSE '' END ||
  CASE WHEN r.rngcollation <> 0 THEN ', COLLATION = ' || coll.collname ELSE '' END ||
  ');' AS ddl
FROM pg_type t
JOIN pg_namespace n ON n.oid = t.typnamespace
JOIN pg_range r ON r.rngtypid = t.oid
LEFT JOIN pg_opclass op ON op.oid = r.rngsubopc
LEFT JOIN pg_collation coll ON coll.oid = r.rngcollation
WHERE t.typtype = 'r'
  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND NOT EXISTS (
    SELECT 1 FROM pg_depend d
    JOIN pg_extension ext ON ext.oid = d.refobjid
    WHERE d.objid = t.oid AND d.deptype = 'e'
  )

ORDER BY ddl;