# Check: access_audit_coverage

Fraction of tables in the schema that have at least one recorded access event in Snowflake's immutable audit log.

## Context

Uses `snowflake.account_usage.access_history` with a 7-day lookback window and a 100,000-row cap on flattened results to limit scan cost on large accounts. The diagnostic query uses the full 30-day window.

`access_history` has approximately 2-hour latency — recently created or accessed tables may not appear yet. Requires IMPORTED PRIVILEGES on the SNOWFLAKE database.

A score of 1.0 means every base table in the schema has been accessed (and therefore audited) within the window. Tables with no access events in the window score as unaudited, which may simply mean they haven't been queried recently — not that auditing is broken.

## SQL

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
access_sample AS (
    SELECT
        f.value:objectName::STRING AS object_name
    FROM snowflake.account_usage.access_history,
        LATERAL FLATTEN(input => direct_objects_accessed) f
    WHERE f.value:objectDomain::STRING = 'Table'
        AND UPPER(SPLIT_PART(f.value:objectName::STRING, '.', 1)) = UPPER('{{ database }}')
        AND UPPER(SPLIT_PART(f.value:objectName::STRING, '.', 2)) = UPPER('{{ schema }}')
        AND query_start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
    LIMIT 100000
),
audited_tables AS (
    SELECT COUNT(DISTINCT object_name) AS cnt
    FROM access_sample
)
SELECT
    audited_tables.cnt AS tables_with_audit,
    table_count.cnt AS total_tables,
    audited_tables.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
FROM table_count, audited_tables
```