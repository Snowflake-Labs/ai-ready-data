# Check: transformation_documentation

Fraction of transformations (views, dynamic tables, materialized views) in the schema whose `COMMENT` describes the transformation in more than 20 characters.

## Context

A transformation is considered "documented" when its `COMMENT` is non-null and longer than 20 characters — short or empty comments are treated as undocumented. The check does not validate comment *quality*, only presence.

Returns NULL (N/A) when the schema contains no transformations.

## SQL

```sql
WITH transformations AS (
    SELECT
        table_type,
        comment
    FROM {{ database }}.information_schema.tables
    WHERE UPPER(table_schema) = UPPER('{{ schema }}')
        AND table_type IN ('VIEW','DYNAMIC TABLE','MATERIALIZED VIEW')
)
SELECT
    COUNT_IF(comment IS NOT NULL AND LENGTH(comment) > 20) AS documented_count,
    COUNT(*) AS total_count,
    COUNT_IF(comment IS NOT NULL AND LENGTH(comment) > 20)::FLOAT
        / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM transformations
```
