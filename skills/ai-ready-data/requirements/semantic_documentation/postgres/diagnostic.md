# Diagnostic: semantic_documentation

Identifies columns lacking semantic descriptions (comments).

## Context

Lists every column on base tables in the schema with its current comment (or empty string if none). Columns without comments are surfaced first so you can prioritize documentation effort.

PostgreSQL has no semantic views — the Snowflake "semantic view inventory" diagnostic variant is not applicable. This diagnostic focuses solely on column-level comment coverage.

## SQL

```sql
SELECT
    c.relname AS table_name,
    a.attname AS column_name,
    format_type(a.atttypid, a.atttypmod) AS data_type,
    CASE
        WHEN col_description(a.attrelid, a.attnum) IS NOT NULL
         AND col_description(a.attrelid, a.attnum) != ''
        THEN 'DOCUMENTED'
        ELSE 'UNDOCUMENTED'
    END AS documentation_status,
    COALESCE(col_description(a.attrelid, a.attnum), '') AS current_comment,
    CASE
        WHEN col_description(a.attrelid, a.attnum) IS NOT NULL
         AND col_description(a.attrelid, a.attnum) != ''
        THEN 'Column documented'
        ELSE 'Add COMMENT ON COLUMN with semantic description'
    END AS recommendation
FROM pg_attribute a
JOIN pg_class c ON c.oid = a.attrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = '{{ schema }}'
  AND c.relkind = 'r'
  AND a.attnum > 0
  AND NOT a.attisdropped
ORDER BY documentation_status DESC, c.relname, a.attnum
```
