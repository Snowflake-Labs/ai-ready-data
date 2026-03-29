# Diagnostic: bias_testing_coverage

Per-table breakdown of bias testing status.

## Context

Shows each base table with its bias-related tag (if any) and a status label: `TESTED` if any recognized bias tag exists, `NOT_TESTED` otherwise. Use this to identify which specific tables need bias evaluation.

Recognized tags: `bias_tested`, `bias_test_date`, `fairness_tested`, `bias_status`.

`account_usage.tag_references` has approximately 2-hour latency.

## SQL

```sql
SELECT
    t.table_name,
    t.row_count,
    tr.tag_name AS bias_tag,
    tr.tag_value AS bias_value,
    CASE
        WHEN tr.tag_name IS NOT NULL THEN 'TESTED'
        ELSE 'NOT_TESTED'
    END AS status
FROM {{ database }}.information_schema.tables t
LEFT JOIN snowflake.account_usage.tag_references tr
    ON UPPER(tr.object_database) = UPPER('{{ database }}')
    AND UPPER(tr.object_schema) = UPPER('{{ schema }}')
    AND UPPER(tr.object_name) = UPPER(t.table_name)
    AND tr.domain = 'TABLE'
    AND LOWER(tr.tag_name) IN ('bias_tested', 'bias_test_date', 'fairness_tested', 'bias_status')
WHERE t.table_schema = '{{ schema }}'
    AND t.table_type = 'BASE TABLE'
ORDER BY status DESC, t.table_name
```
