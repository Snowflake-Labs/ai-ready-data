# Check: native_format_availability

Fraction of datasets stored in consumption-ready formats without requiring runtime format conversion.

## Context

In PostgreSQL, "native format" means data stored using proper typed columns rather than stuffing structured data into TEXT columns. This check identifies columns that store JSON-like data as TEXT instead of using PostgreSQL's native JSONB type, and flags tables with foreign data wrappers (foreign tables) that require runtime conversion.

The score is the fraction of in-scope tables that are fully native — meaning no TEXT columns containing JSON-like data and no foreign table wrappers.

## SQL

```sql
WITH tables_in_scope AS (
    SELECT
        t.table_name,
        t.table_type,
        CASE
            WHEN t.table_type = 'FOREIGN' THEN 'EXTERNAL'
            WHEN EXISTS (
                SELECT 1
                FROM information_schema.columns c
                WHERE c.table_schema = '{{ schema }}'
                    AND c.table_name = t.table_name
                    AND c.data_type = 'text'
                    AND (LOWER(c.column_name) LIKE '%json%'
                         OR LOWER(c.column_name) LIKE '%payload%'
                         OR LOWER(c.column_name) LIKE '%document%'
                         OR LOWER(c.column_name) LIKE '%body%')
            ) THEN 'TEXT_JSON'
            ELSE 'NATIVE'
        END AS format_type
    FROM information_schema.tables t
    WHERE t.table_schema = '{{ schema }}'
        AND t.table_type IN ('BASE TABLE', 'FOREIGN')
)
SELECT
    COUNT(*) FILTER (WHERE format_type = 'NATIVE') AS native_count,
    COUNT(*) AS total_count,
    COUNT(*) FILTER (WHERE format_type = 'NATIVE')::NUMERIC / NULLIF(COUNT(*)::NUMERIC, 0) AS value
FROM tables_in_scope
```
