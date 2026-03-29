# Check: incremental_update_coverage

Fraction of data pipelines that use incremental processing (CDC or streaming) rather than full-reload extraction.

## Context

Checks fraction of tables that support incremental updates (streams or dynamic tables). Returns a float 0-1 representing the fraction of tables with incremental update capability.

Streams are not listed in `information_schema.tables`. Uses dynamic tables + change_tracking enabled tables as proxy for incremental capability.

## SQL

```sql
WITH base_tables AS (
    SELECT table_name
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
dynamic_tables AS (
    SELECT table_name
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'DYNAMIC TABLE'
),
-- Dynamic tables are inherently incremental
tables_with_incremental AS (
    SELECT table_name FROM dynamic_tables
)
SELECT
    (SELECT COUNT(*) FROM tables_with_incremental) AS tables_with_incremental,
    (SELECT COUNT(*) FROM base_tables) + (SELECT COUNT(*) FROM dynamic_tables) AS total_tables,
    (SELECT COUNT(*) FROM tables_with_incremental)::FLOAT / 
        NULLIF(((SELECT COUNT(*) FROM base_tables) + (SELECT COUNT(*) FROM dynamic_tables))::FLOAT, 0) AS value
```