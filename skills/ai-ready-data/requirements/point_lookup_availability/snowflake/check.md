# Check: point_lookup_availability

Fraction of base tables in the schema that support low-latency key-based lookups via a clustering key or search optimization.

## Context

A table qualifies as "point-lookup capable" if it has **either** a clustering key defined (`cluster_by` is non-empty) **or** search optimization enabled (`search_optimization = 'ON'`). These are the two mechanisms Snowflake exposes for sub-second lookups on large tables without a separate index.

Requires `SHOW TABLES` + `RESULT_SCAN` in the **same session** — clustering and search-optimization status are not exposed in `information_schema.tables`. If the session is reset between the two statements, `RESULT_SCAN` will fail.

Returns NULL (N/A) when the schema contains no base tables.

## SQL

```sql
SHOW TABLES IN SCHEMA {{ database }}.{{ schema }};

WITH show_results AS (
    SELECT
        "name" AS table_name,
        "cluster_by" AS cluster_by,
        "search_optimization" AS search_optimization
    FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
    WHERE "kind" = 'TABLE'
)
SELECT
    COUNT_IF((cluster_by IS NOT NULL AND cluster_by <> '') OR search_optimization = 'ON')
        AS tables_with_lookup,
    COUNT(*) AS total_tables,
    COUNT_IF((cluster_by IS NOT NULL AND cluster_by <> '') OR search_optimization = 'ON')::FLOAT
        / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM show_results
```
