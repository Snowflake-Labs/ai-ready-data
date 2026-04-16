# Check: temporal_scope_declaration

Fraction of temporal columns (DATE/TIMESTAMP family) across base tables that have a non-empty `COMMENT`.

## Context

Scans `information_schema.columns` (joined to `information_schema.tables` with `table_type = 'BASE TABLE'`) for all date and timestamp types — `DATE`, `DATETIME`, `TIMESTAMP_LTZ`, `TIMESTAMP_NTZ`, `TIMESTAMP_TZ`, `TIME` — and checks whether each has a non-empty `comment`. Restricting to base tables prevents view-column comments from inflating the score.

A score of 1.0 means every temporal column in a base table has a comment describing its temporal role (validity window, effective date, event time, etc.). The check does not validate comment content — only presence.

Returns NULL (N/A) when the schema contains no temporal columns in base tables.

## SQL

```sql
WITH temporal_columns AS (
    SELECT c.comment
    FROM {{ database }}.information_schema.columns c
    JOIN {{ database }}.information_schema.tables t
        ON c.table_catalog = t.table_catalog
        AND c.table_schema = t.table_schema
        AND c.table_name   = t.table_name
    WHERE UPPER(c.table_schema) = UPPER('{{ schema }}')
        AND t.table_type = 'BASE TABLE'
        AND c.data_type IN ('DATE','DATETIME','TIMESTAMP_LTZ','TIMESTAMP_NTZ','TIMESTAMP_TZ','TIME')
)
SELECT
    COUNT_IF(comment IS NOT NULL AND comment <> '') AS documented_temporal_columns,
    COUNT(*) AS total_temporal_columns,
    COUNT_IF(comment IS NOT NULL AND comment <> '')::FLOAT
        / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM temporal_columns
```
