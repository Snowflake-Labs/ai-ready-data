# Diagnostic: bias_testing_coverage

Per-table breakdown of bias testing documentation status.

## Context

Shows each base table with its table comment and a status label: `TESTED` if the comment contains recognized bias testing keywords, `NOT_TESTED` otherwise. Use this to identify which specific tables need bias evaluation.

Recognized keywords in comments: `bias_tested`, `bias_test`, `fairness_tested`, `fairness_test`, `bias_status`.

## SQL

```sql
SELECT
    c.relname AS table_name,
    COALESCE(s.n_live_tup, 0) AS estimated_row_count,
    obj_description(c.oid) AS table_comment,
    CASE
        WHEN obj_description(c.oid) IS NOT NULL
            AND (
                LOWER(obj_description(c.oid)) LIKE '%bias_tested%'
                OR LOWER(obj_description(c.oid)) LIKE '%bias_test%'
                OR LOWER(obj_description(c.oid)) LIKE '%fairness_tested%'
                OR LOWER(obj_description(c.oid)) LIKE '%fairness_test%'
                OR LOWER(obj_description(c.oid)) LIKE '%bias_status%'
            )
        THEN 'TESTED'
        ELSE 'NOT_TESTED'
    END AS status
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_stat_user_tables s ON s.relid = c.oid
WHERE n.nspname = '{{ schema }}'
    AND c.relkind = 'r'
ORDER BY status DESC, c.relname
```
