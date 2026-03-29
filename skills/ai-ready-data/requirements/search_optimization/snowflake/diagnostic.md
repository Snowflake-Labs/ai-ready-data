# Diagnostic: search_optimization

Per-table breakdown of search optimization status.

## Context

Lists every table in the schema with its row count, size in bytes, and whether search optimization is enabled. Results are sorted so optimized tables appear first, then by row count descending to surface the largest unoptimized tables.

Only enable on tables >1GB — smaller tables gain little benefit and incur storage overhead from the search access path.

## SQL

```sql
SHOW TABLES IN SCHEMA {{ database }}.{{ schema }};

SELECT
    "name" AS table_name,
    "rows" AS row_count,
    "bytes" AS size_bytes,
    "search_optimization",
    CASE
        WHEN "search_optimization" = 'ON' THEN 'ENABLED'
        ELSE 'NOT ENABLED'
    END AS status
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "kind" = 'TABLE'
ORDER BY "search_optimization" DESC, "rows" DESC
```
