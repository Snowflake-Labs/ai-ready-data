# Diagnostic: native_format_availability

Shows each table's format type (native vs external/text-json) with size and a recommendation.

## Context

Classifies each table as NATIVE, EXTERNAL (foreign table), or TEXT_JSON (has TEXT columns with JSON-like names that should be JSONB). Includes estimated row count and table size from PostgreSQL catalog statistics.

## SQL

```sql
SELECT
    t.table_schema AS schema_name,
    t.table_name,
    t.table_type,
    COALESCE(s.n_live_tup, 0) AS estimated_row_count,
    pg_size_pretty(pg_total_relation_size(quote_ident(t.table_schema) || '.' || quote_ident(t.table_name))) AS table_size,
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
    END AS format_type,
    CASE
        WHEN t.table_type = 'FOREIGN' THEN 'Foreign table - requires runtime conversion from external source'
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
        ) THEN 'Has TEXT columns storing JSON-like data - migrate to JSONB'
        ELSE 'Native PostgreSQL format - optimal performance'
    END AS recommendation
FROM information_schema.tables t
LEFT JOIN pg_stat_user_tables s
    ON s.schemaname = t.table_schema AND s.relname = t.table_name
WHERE t.table_schema = '{{ schema }}'
    AND t.table_type IN ('BASE TABLE', 'FOREIGN')
ORDER BY format_type DESC, t.table_name
```
