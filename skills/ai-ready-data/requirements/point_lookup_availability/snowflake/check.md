# Check: point_lookup_availability

Fraction of entity records accessible via low-latency key-based point lookups.

## Context

Uses `information_schema.tables` to count base tables in scope. Accurate clustering and search optimization status requires `SHOW TABLES` + `RESULT_SCAN`, which cannot be combined in a single CTE-based query — so this check returns a placeholder `0.0` value. Run the commented-out `SHOW TABLES` command and inspect `cluster_by` / `search_optimization` columns for actual results.

## SQL

```sql
-- check-point-lookup-availability.sql
-- Checks fraction of tables with clustering or search optimization for fast lookups
-- Returns: value (float 0-1) - fraction of tables with point lookup capability

-- Note: Requires SHOW TABLES + RESULT_SCAN for clustering key info
WITH tables_in_scope AS (
    SELECT table_name
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
)
SELECT
    0 AS tables_with_clustering,  -- Placeholder: requires SHOW TABLES
    (SELECT COUNT(*) FROM tables_in_scope) AS total_tables,
    0.0 AS value
-- For accurate results, run:
-- SHOW TABLES IN SCHEMA {{ database }}.{{ schema }};
-- Then check "cluster_by" IS NOT NULL OR "search_optimization" = 'ON'
```
