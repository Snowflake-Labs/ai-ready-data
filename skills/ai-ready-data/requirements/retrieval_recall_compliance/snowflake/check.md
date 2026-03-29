# Check: retrieval_recall_compliance

Fraction of vector search indexes achieving their target recall threshold at required query latency.

## Context

Recall measurement requires ground-truth queries — this check proxies via index presence. It counts tables with VECTOR columns and checks whether search optimization is enabled. Since `search_optimization` is not available in `information_schema.tables`, this query returns a placeholder value of 0.0. For accurate results, use `SHOW TABLES` and inspect the `search_optimization` column.

A score of 1.0 would mean every vector table has search optimization enabled, proxying for recall compliance.

## SQL

```sql
-- check-retrieval-recall-compliance.sql
-- Checks if vector tables have search optimization for recall compliance
-- Returns: value (float 0-1) - fraction of vector tables with search optimization
-- Note: search_optimization is not in information_schema.tables — requires SHOW TABLES.
-- This check proxies by counting tables with VECTOR columns as a baseline.

WITH vector_tables AS (
    SELECT COUNT(DISTINCT c.table_name) AS total_vector_tables
    FROM {{ database }}.information_schema.columns c
    JOIN {{ database }}.information_schema.tables t
        ON c.table_name = t.table_name AND c.table_schema = t.table_schema
    WHERE c.table_schema = '{{ schema }}'
        AND t.table_type = 'BASE TABLE'
        AND c.data_type LIKE 'VECTOR%'
)
SELECT
    0 AS indexed_tables,  -- Placeholder: requires SHOW TABLES for search_optimization
    vector_tables.total_vector_tables AS total_vector_tables,
    0.0 AS value
FROM vector_tables
-- For accurate results, run:
-- SHOW TABLES IN SCHEMA {{ database }}.{{ schema }};
-- Then check "search_optimization" = 'ON' for tables with VECTOR columns
```
