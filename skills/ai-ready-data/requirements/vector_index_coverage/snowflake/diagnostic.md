# Diagnostic: vector_index_coverage

Per-table breakdown of vector tables and their search optimization status.

## Context

Requires a two-step execution in the same Snowflake session: first run `SHOW TABLES IN SCHEMA {{ database }}.{{ schema }};`, then run the query below which reads the results via `RESULT_SCAN`. Tables with `search_optimization = 'ON'` are considered indexed; all others need `ALTER TABLE ... SET SEARCH_OPTIMIZATION = ON`.

## SQL

```sql
-- diagnostic-vector-index-coverage.sql
-- Shows vector tables and their search optimization status
-- Requires: SHOW TABLES followed by RESULT_SCAN in same session

-- Step 1: Run this first
-- SHOW TABLES IN SCHEMA {{ database }}.{{ schema }};

-- Step 2: Then run this query to see vector tables with search optimization status
WITH vector_tables AS (
    SELECT DISTINCT
        c.table_schema,
        c.table_name
    FROM {{ database }}.information_schema.columns c
    WHERE c.table_schema = '{{ schema }}'
        AND c.data_type LIKE 'VECTOR%'
)
SELECT
    "database_name" AS database_name,
    "schema_name" AS schema_name,
    "name" AS table_name,
    "search_optimization" AS search_optimization_status,
    CASE
        WHEN "search_optimization" = 'ON' THEN 'INDEXED'
        ELSE 'NOT_INDEXED'
    END AS index_status,
    CASE
        WHEN "search_optimization" = 'ON' THEN 'Vector search optimization enabled'
        ELSE 'Run: ALTER TABLE ... SET SEARCH_OPTIMIZATION = ON'
    END AS recommendation
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "name" IN (SELECT table_name FROM vector_tables)
ORDER BY index_status DESC, "name"
```
