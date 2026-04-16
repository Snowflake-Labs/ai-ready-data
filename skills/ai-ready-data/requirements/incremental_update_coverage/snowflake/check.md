# Check: incremental_update_coverage

Fraction of tables in the schema that support incremental updates — either implemented as a dynamic table or with change tracking enabled on a base table.

## Context

Two signals count toward "incremental-capable":

1. **Dynamic tables** — inherently incremental via Snowflake's declarative refresh.
2. **Base tables with `change_tracking = 'ON'`** — downstream consumers can use streams or `CHANGES` queries.

`change_tracking` is not exposed in `information_schema.tables`, so this check uses `SHOW TABLES` + `RESULT_SCAN` (same-session requirement). Dynamic tables are discovered from `information_schema.tables`.

Returns NULL (N/A) when the schema contains no base or dynamic tables.

## SQL

```sql
SHOW TABLES IN SCHEMA {{ database }}.{{ schema }};

WITH show_results AS (
    SELECT
        UPPER("name") AS table_name,
        "change_tracking" AS change_tracking
    FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
    WHERE "kind" = 'TABLE'
),
tables_in_scope AS (
    SELECT
        UPPER(table_name) AS table_name,
        table_type
    FROM {{ database }}.information_schema.tables
    WHERE UPPER(table_schema) = UPPER('{{ schema }}')
      AND table_type IN ('BASE TABLE','DYNAMIC TABLE')
)
SELECT
    COUNT_IF(
        t.table_type = 'DYNAMIC TABLE'
        OR s.change_tracking = 'ON'
    ) AS tables_with_incremental,
    COUNT(*) AS total_tables,
    COUNT_IF(
        t.table_type = 'DYNAMIC TABLE'
        OR s.change_tracking = 'ON'
    )::FLOAT / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM tables_in_scope t
LEFT JOIN show_results s
    ON s.table_name = t.table_name
```
