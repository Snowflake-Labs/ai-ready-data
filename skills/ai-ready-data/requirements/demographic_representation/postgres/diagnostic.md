# Diagnostic: demographic_representation

Per-table breakdown of demographic documentation status showing which tables and columns carry demographic metadata.

## Context

Lists every base table in the schema with its table comment, any column comments containing demographic keywords, and a status label. Tables without any matching documentation appear as `NOT_DOCUMENTED`.

Recognized keywords: `demographic`, `protected_class`, `sensitive_attribute`, `fairness_attribute`. Demographic attributes are sensitive — handle with appropriate access controls.

## SQL

```sql
SELECT
    c.relname AS table_name,
    COALESCE(s.n_live_tup, 0) AS estimated_row_count,
    obj_description(c.oid) AS table_comment,
    (
        SELECT STRING_AGG(a.attname || ': ' || col_description(a.attrelid, a.attnum), '; ')
        FROM pg_attribute a
        WHERE a.attrelid = c.oid
            AND a.attnum > 0
            AND NOT a.attisdropped
            AND col_description(a.attrelid, a.attnum) IS NOT NULL
            AND (
                LOWER(col_description(a.attrelid, a.attnum)) LIKE '%demographic%'
                OR LOWER(col_description(a.attrelid, a.attnum)) LIKE '%protected_class%'
                OR LOWER(col_description(a.attrelid, a.attnum)) LIKE '%sensitive_attribute%'
                OR LOWER(col_description(a.attrelid, a.attnum)) LIKE '%fairness_attribute%'
            )
    ) AS demographic_column_comments,
    CASE
        WHEN obj_description(c.oid) IS NOT NULL
            AND (
                LOWER(obj_description(c.oid)) LIKE '%demographic%'
                OR LOWER(obj_description(c.oid)) LIKE '%protected_class%'
                OR LOWER(obj_description(c.oid)) LIKE '%sensitive_attribute%'
                OR LOWER(obj_description(c.oid)) LIKE '%fairness_attribute%'
            )
        THEN 'DOCUMENTED'
        WHEN EXISTS (
            SELECT 1
            FROM pg_attribute a
            WHERE a.attrelid = c.oid
                AND a.attnum > 0
                AND NOT a.attisdropped
                AND col_description(a.attrelid, a.attnum) IS NOT NULL
                AND (
                    LOWER(col_description(a.attrelid, a.attnum)) LIKE '%demographic%'
                    OR LOWER(col_description(a.attrelid, a.attnum)) LIKE '%protected_class%'
                    OR LOWER(col_description(a.attrelid, a.attnum)) LIKE '%sensitive_attribute%'
                    OR LOWER(col_description(a.attrelid, a.attnum)) LIKE '%fairness_attribute%'
                )
        ) THEN 'DOCUMENTED'
        ELSE 'NOT_DOCUMENTED'
    END AS status
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_stat_user_tables s ON s.relid = c.oid
WHERE n.nspname = '{{ schema }}'
    AND c.relkind = 'r'
ORDER BY status DESC, c.relname
```
