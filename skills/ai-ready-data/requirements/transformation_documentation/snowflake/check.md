# Check: transformation_documentation

Fraction of data transformations with documented logic, inputs, and outputs.

## Context

Queries `information_schema.tables` for views, dynamic tables, and materialized views in the target schema. A transformation is considered documented if its `COMMENT` is non-null and longer than 20 characters — short or empty comments are treated as undocumented.

A score of 1.0 means every transformation object has a meaningful comment describing its logic.

## SQL

```sql
WITH transformations AS (
    SELECT
        table_name,
        table_type,
        comment
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type IN ('VIEW', 'DYNAMIC TABLE', 'MATERIALIZED VIEW')
),
documented_transformations AS (
    SELECT * FROM transformations
    WHERE comment IS NOT NULL AND LENGTH(comment) > 20
)
SELECT
    (SELECT COUNT(*) FROM documented_transformations) AS documented_count,
    (SELECT COUNT(*) FROM transformations) AS total_count,
    (SELECT COUNT(*) FROM documented_transformations)::FLOAT / 
        NULLIF((SELECT COUNT(*) FROM transformations)::FLOAT, 0) AS value
```
