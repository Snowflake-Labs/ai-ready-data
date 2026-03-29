# Diagnostic: demographic_representation

Per-table breakdown of demographic documentation status showing which tables and columns carry demographic tags.

## Context

Lists every base table in the schema with its tag name, tag value, and column (if the tag is column-level). Tables without any matching tag appear as `NOT_DOCUMENTED`. Uses `snowflake.account_usage.tag_references` which has approximately 2-hour latency — recently applied tags may not appear yet.

Recognized tag names: `demographic`, `protected_class`, `sensitive_attribute`, `fairness_attribute`. Demographic attributes are sensitive — handle with appropriate access controls.

## SQL

```sql
SELECT
    t.table_name,
    t.row_count,
    tr.tag_name,
    tr.tag_value,
    tr.column_name,
    CASE
        WHEN tr.tag_name IS NOT NULL THEN 'DOCUMENTED'
        ELSE 'NOT_DOCUMENTED'
    END AS status
FROM {{ database }}.information_schema.tables t
LEFT JOIN snowflake.account_usage.tag_references tr
    ON UPPER(tr.object_database) = UPPER('{{ database }}')
    AND UPPER(tr.object_schema) = UPPER('{{ schema }}')
    AND UPPER(tr.object_name) = UPPER(t.table_name)
    AND LOWER(tr.tag_name) IN ('demographic', 'protected_class', 'sensitive_attribute', 'fairness_attribute')
WHERE t.table_schema = '{{ schema }}'
    AND t.table_type = 'BASE TABLE'
ORDER BY status DESC, t.table_name
```