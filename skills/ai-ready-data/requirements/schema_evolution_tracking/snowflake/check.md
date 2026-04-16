# Check: schema_evolution_tracking

Fraction of base tables whose schema history is observable via `SNOWFLAKE.ACCOUNT_USAGE.COLUMNS`.

## Context

AI-ready data products support programmatic reasoning about schema change over time. In Snowflake, column lifecycle (adds, drops, type changes) is captured in `SNOWFLAKE.ACCOUNT_USAGE.COLUMNS`, which records every historical column version with `created` and `deleted` timestamps.

A base table is considered "tracked" when the view has at least one row for it — either a currently-present column or a historically-dropped one. This is a capability check, not a churn measure: the presence of history is what matters.

Caveats:

- `ACCOUNT_USAGE.COLUMNS` has approximately **2-hour latency**. Very new tables won't appear yet and will look untracked.
- Requires `IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE`.
- Distinct from `data_version_coverage` (which measures Time Travel retention): a table can have Time Travel without column history, or vice versa.

Returns NULL (N/A) when the schema contains no base tables.

## SQL

```sql
WITH base_tables AS (
    SELECT UPPER(table_name) AS table_name
    FROM {{ database }}.information_schema.tables
    WHERE UPPER(table_schema) = UPPER('{{ schema }}')
        AND table_type = 'BASE TABLE'
),
tracked_tables AS (
    SELECT DISTINCT UPPER(table_name) AS table_name
    FROM snowflake.account_usage.columns
    WHERE UPPER(table_catalog) = UPPER('{{ database }}')
        AND UPPER(table_schema) = UPPER('{{ schema }}')
)
SELECT
    COUNT_IF(b.table_name IN (SELECT table_name FROM tracked_tables))
        AS tables_with_history,
    COUNT(*) AS total_tables,
    COUNT_IF(b.table_name IN (SELECT table_name FROM tracked_tables))::FLOAT
        / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM base_tables b
```
