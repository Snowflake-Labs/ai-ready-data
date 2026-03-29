# Check: access_optimization

Fraction of large tables in the schema that have clustering keys defined.

## Context

Only tables with more than 10,000 rows are evaluated — small tables don't benefit from clustering and would inflate the score. If the schema has no tables above this threshold, the check returns NULL (division by zero guard), which should be treated as not applicable.

A clustering key being *present* does not mean it is *effective*. Use the diagnostic to assess clustering depth on individual tables.

## SQL

```sql
WITH large_tables AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
        AND row_count > 10000
),
clustered AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
        AND row_count > 10000
        AND clustering_key IS NOT NULL
)
SELECT
    clustered.cnt AS clustered_tables,
    large_tables.cnt AS large_tables,
    clustered.cnt::FLOAT / NULLIF(large_tables.cnt::FLOAT, 0) AS value
FROM large_tables, clustered
```
