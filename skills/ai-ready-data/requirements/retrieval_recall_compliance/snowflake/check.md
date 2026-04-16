# Check: retrieval_recall_compliance

Fraction of vector-bearing tables whose vector columns have search optimization enabled — a proxy for recall compliance at acceptable latency.

## Context

True recall measurement requires a labeled query/ground-truth set, which Snowflake does not expose. This check proxies compliance by asking: of the tables that contain a `VECTOR` column, how many have search optimization enabled on the table? Search optimization is the platform feature that backs ANN recall at low latency.

Requires `SHOW TABLES` + `RESULT_SCAN` in the **same session** — search-optimization status is not in `information_schema.tables`.

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
    COUNT_IF(s.search_optimization = 'ON') AS indexed_vector_tables,
    COUNT(*) AS total_vector_tables,
    COUNT_IF(s.search_optimization = 'ON')::FLOAT
        / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM vector_tables v
JOIN show_results s USING (table_name)
```
