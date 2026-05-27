You are absolutely right to point out the error. My apologies. The error message you're seeing is because the query you executed was malformed due to a copy-paste issue where the query text was duplicated and cut off.

The error `syntax error at or near "table_schema"` occurs because the parser sees the end of the first `ORDER BY` clause get cut off and immediately run into the `SELECT` from the duplicated query, which is invalid SQL syntax.

Let me provide the corrected, clean scripts again.

---

### Corrected Script (Using `query_to_xml`)

This is the corrected version of the script you tried to run. Please copy this clean version.

```sql
SELECT 
    table_schema,
    table_name,
    (xpath('/row/cnt/text()', xml_count))[1]::text::bigint AS row_count
FROM (
  SELECT 
    table_schema, 
    table_name, 
    query_to_xml(format('SELECT count(*) AS cnt FROM %I.%I', table_schema, table_name), false, true, '') AS xml_count
  FROM 
    information_schema.tables
  WHERE 
    table_schema NOT IN ('pg_catalog', 'information_schema') -- Exclude system schemas
    AND table_type = 'BASE TABLE'
) AS t
ORDER BY 
    row_count DESC;
```

---

### Alternative and Simpler Script (Recommended)

While the `query_to_xml` method works, a much more direct and standard way to get these fast, approximate counts is to query the `pg_class` system catalog directly. **This script is generally recommended over the one above** because it's simpler and more efficient.

```sql
SELECT
    n.nspname AS table_schema,
    c.relname AS table_name,
    c.reltuples::bigint AS row_count
FROM
    pg_class c
JOIN
    pg_namespace n ON n.oid = c.relnamespace
WHERE
    c.relkind = 'r' -- 'r' for regular tables
    AND n.nspname NOT IN ('pg_catalog', 'information_schema') -- Exclude system schemas
ORDER BY
    row_count DESC;
```

### Why the Alternative is Often Better:

*   **Simplicity:** It's much easier to read and understand.
*   **No XML Parsing:** It avoids the overhead of converting a count to XML and then parsing it with `xpath`, which is computationally more expensive.
*   **Direct Access:** It directly accesses the `reltuples` column, which is the exact statistic that PostgreSQL's query planner uses.

Please try the alternative script, as it should give you the same results more efficiently and with less complex syntax.