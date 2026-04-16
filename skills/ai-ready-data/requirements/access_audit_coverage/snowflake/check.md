# Check: access_audit_coverage

Fraction of base tables in the schema that appear as an accessed object in Snowflake's immutable audit log within the last 7 days.

## Context

Uses `snowflake.account_usage.access_history` with a 7-day lookback window. The flattened `direct_objects_accessed` stream is deterministically ordered by `query_start_time DESC` and capped at 100,000 rows to limit scan cost on high-traffic accounts — the `ORDER BY` keeps repeated runs stable. The diagnostic query uses the full 30-day window.

`access_history` has approximately 2-hour latency — recently created or accessed tables may not appear yet. Requires `IMPORTED PRIVILEGES` on the `SNOWFLAKE` database.

A score of 1.0 means every base table in the schema has been read at least once in the window (and is therefore audited). Tables with no events score as unaudited — which may simply mean they haven't been queried recently, not that auditing is broken.

Returns NULL (N/A) when the schema contains no base tables.

## SQL

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE UPPER(table_schema) = UPPER('{{ schema }}')
        AND table_type = 'BASE TABLE'
),
recent_access AS (
    SELECT
        query_start_time,
        direct_objects_accessed
    FROM snowflake.account_usage.access_history
    WHERE query_start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
    ORDER BY query_start_time DESC
    LIMIT 100000
),
access_sample AS (
    SELECT
        UPPER(SPLIT_PART(f.value:objectName::STRING, '.', 3)) AS table_name
    FROM recent_access,
         LATERAL FLATTEN(input => direct_objects_accessed) f
    WHERE f.value:objectDomain::STRING = 'Table'
        AND UPPER(SPLIT_PART(f.value:objectName::STRING, '.', 1)) = UPPER('{{ database }}')
        AND UPPER(SPLIT_PART(f.value:objectName::STRING, '.', 2)) = UPPER('{{ schema }}')
),
audited_tables AS (
    SELECT COUNT(DISTINCT table_name) AS cnt
    FROM access_sample
)
SELECT
    audited_tables.cnt AS tables_with_audit,
    table_count.cnt    AS total_tables,
    audited_tables.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
FROM table_count, audited_tables
```
