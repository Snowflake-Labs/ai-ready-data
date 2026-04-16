# Check: vector_index_coverage

Fraction of tables with a `VECTOR` column that have search optimization enabled — Snowflake's mechanism for backing vector similarity search with an on-disk index.

## Context

Snowflake vector search optimization is enabled per-table via:

```sql
ALTER TABLE <t> ADD SEARCH OPTIMIZATION ON EQUALITY(<col>);
```

This check identifies tables in the target schema whose `data_type` starts with `VECTOR` and reports the fraction with search optimization turned on. Requires `SHOW TABLES` + `RESULT_SCAN` in the **same session** — search-optimization status is not exposed in `information_schema.tables`.

Returns NULL (N/A) when the schema contains no vector-bearing tables.

## SQL

```sql
SHOW TABLES IN SCHEMA {{ database }}.{{ schema }};

WITH show_results AS (
    SELECT
        UPPER("name") AS table_name,
        "search_optimization" AS search_optimization
    FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
    WHERE "kind" = 'TABLE'
),
vector_tables AS (
    SELECT DISTINCT UPPER(c.table_name) AS table_name
    FROM {{ database }}.information_schema.columns c
    WHERE UPPER(c.table_schema) = UPPER('{{ schema }}')
      AND c.data_type LIKE 'VECTOR%'
)
SELECT
    COUNT_IF(s.search_optimization = 'ON') AS tables_with_vector_index,
    COUNT(*) AS total_vector_tables,
    COUNT_IF(s.search_optimization = 'ON')::FLOAT
        / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM vector_tables v
JOIN show_results s USING (table_name)
```
