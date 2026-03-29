# Check: lineage_completeness

Fraction of tables with documented end-to-end lineage from source through transformations, verified via Snowflake's `ACCESS_HISTORY`.

## Context

Uses `snowflake.account_usage.access_history` with a 7-day lookback window and a 100,000-row cap on flattened `base_objects_accessed` to limit scan cost on large accounts. The diagnostic query retains the full 30-day window.

`ACCESS_HISTORY` has approximately 2-hour latency — recently created or accessed objects may not yet appear. Requires IMPORTED PRIVILEGES on the SNOWFLAKE database.

A score of 1.0 means every base table in the schema has at least one lineage record (i.e., appears as a base object accessed in a query). Tables absent from the window score as having no documented lineage, which may simply mean they haven't been read as a source recently.

## SQL

```sql
-- check-lineage-completeness.sql
-- Checks fraction of tables with documented lineage in ACCESS_HISTORY
-- Returns: value (float 0-1) - fraction of tables with lineage data

-- Note: ACCESS_HISTORY has ~2 hour latency for new objects.
-- Uses 7-day window (not 30) and caps flattened rows to limit scan cost
-- on large accounts. Diagnostic query retains full 30-day window.
WITH tables_in_scope AS (
    SELECT DISTINCT table_name
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
access_sample AS (
    SELECT
        obj.value:objectName::STRING AS object_name,
        obj.value:objectDomain::STRING AS object_domain
    FROM snowflake.account_usage.access_history,
        LATERAL FLATTEN(input => base_objects_accessed) obj
    WHERE query_start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP())
        AND obj.value:objectDomain::STRING = 'Table'
        AND UPPER(SPLIT_PART(obj.value:objectName::STRING, '.', 1)) = UPPER('{{ database }}')
        AND UPPER(SPLIT_PART(obj.value:objectName::STRING, '.', 2)) = UPPER('{{ schema }}')
    LIMIT 100000
),
tables_with_lineage AS (
    SELECT DISTINCT
        UPPER(SPLIT_PART(object_name, '.', 3)) AS table_name
    FROM access_sample
)
SELECT
    (SELECT COUNT(*) FROM tables_in_scope t
     WHERE UPPER(t.table_name) IN (SELECT table_name FROM tables_with_lineage)
    ) AS tables_with_lineage,
    (SELECT COUNT(*) FROM tables_in_scope) AS total_tables,
    (SELECT COUNT(*) FROM tables_in_scope t
     WHERE UPPER(t.table_name) IN (SELECT table_name FROM tables_with_lineage)
    )::FLOAT / NULLIF((SELECT COUNT(*) FROM tables_in_scope)::FLOAT, 0) AS value
```