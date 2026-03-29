# Check: search_optimization

Fraction of tables with search optimization enabled.

## Context

Uses `SHOW TABLES` to inspect the `search_optimization` property on every table in the schema. Returns a ratio of optimized tables to total tables.

Only enable on tables >1GB — smaller tables gain little benefit and incur storage overhead from the search access path.

## SQL

```sql
SHOW TABLES IN SCHEMA {{ database }}.{{ schema }};

SELECT
    COUNT_IF("search_optimization" = 'ON') AS optimized_tables,
    COUNT(*) AS total_tables,
    COUNT_IF("search_optimization" = 'ON')::FLOAT / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "kind" = 'TABLE'
```
