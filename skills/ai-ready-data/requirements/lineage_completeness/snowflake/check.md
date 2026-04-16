# Check: lineage_completeness

Fraction of base tables in the schema that appear as a base object (upstream source) in recent `ACCESS_HISTORY` events — a proxy for documented lineage.

## Context

Uses `snowflake.account_usage.access_history` with a 7-day lookback window. The flattened `base_objects_accessed` stream is deterministically ordered by `query_start_time DESC` and capped at 100,000 rows to limit scan cost — the `ORDER BY` keeps repeated runs stable. The diagnostic query uses the full 30-day window.

`access_history` has approximately 2-hour latency. Requires `IMPORTED PRIVILEGES` on the `SNOWFLAKE` database.

A score of 1.0 means every base table in the schema has at least one lineage record — it was read as an upstream source by at least one query in the window. Tables absent from the window may simply not have been read recently, not that lineage is broken.

Returns NULL (N/A) when the schema contains no base tables.

## SQL

```sql
WITH tables_in_scope AS (
    SELECT DISTINCT UPPER(table_name) AS table_name
    FROM {{ database }}.information_schema.tables
    WHERE UPPER(table_schema) = UPPER('{{ schema }}')
        AND table_type = 'BASE TABLE'
),
recent_access AS (
    SELECT
        query_start_time,
        base_objects_accessed
    FROM snowflake.account_usage.access_history
    WHERE query_start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
    ORDER BY query_start_time DESC
    LIMIT 100000
),
access_sample AS (
    SELECT
        UPPER(SPLIT_PART(obj.value:objectName::STRING, '.', 3)) AS table_name
    FROM recent_access,
         LATERAL FLATTEN(input => base_objects_accessed) obj
    WHERE obj.value:objectDomain::STRING = 'Table'
        AND UPPER(SPLIT_PART(obj.value:objectName::STRING, '.', 1)) = UPPER('{{ database }}')
        AND UPPER(SPLIT_PART(obj.value:objectName::STRING, '.', 2)) = UPPER('{{ schema }}')
),
tables_with_lineage AS (
    SELECT DISTINCT table_name FROM access_sample
)
SELECT
    COUNT_IF(t.table_name IN (SELECT table_name FROM tables_with_lineage))
        AS tables_with_lineage,
    COUNT(*) AS total_tables,
    COUNT_IF(t.table_name IN (SELECT table_name FROM tables_with_lineage))::FLOAT
        / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM tables_in_scope t
```
