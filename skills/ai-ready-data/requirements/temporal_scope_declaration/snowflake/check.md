# Check: temporal_scope_declaration

Fraction of temporal columns (date/timestamp) in the schema that have documentation via column comments declaring their temporal role.

## Context

Scans `information_schema.columns` for all date and timestamp types (`DATE`, `DATETIME`, `TIMESTAMP_LTZ`, `TIMESTAMP_NTZ`, `TIMESTAMP_TZ`, `TIME`) and checks whether each has a non-empty `comment`. A score of 1.0 means every temporal column has a comment describing its validity window, effective date, or temporal role.

Columns without comments are assumed undocumented. The check does not validate comment content — only presence.

## SQL

```sql
WITH temporal_columns AS (
    SELECT
        c.table_catalog,
        c.table_schema,
        c.table_name,
        c.column_name,
        c.data_type,
        c.comment
    FROM {{ database }}.information_schema.columns c
    WHERE c.table_schema = '{{ schema }}'
        AND c.data_type IN ('DATE', 'DATETIME', 'TIMESTAMP_LTZ', 'TIMESTAMP_NTZ', 'TIMESTAMP_TZ', 'TIME')
),
documented_temporal AS (
    SELECT *
    FROM temporal_columns
    WHERE comment IS NOT NULL 
        AND comment != ''
)
SELECT
    (SELECT COUNT(*) FROM documented_temporal) AS documented_temporal_columns,
    (SELECT COUNT(*) FROM temporal_columns) AS total_temporal_columns,
    (SELECT COUNT(*) FROM documented_temporal)::FLOAT / 
        NULLIF((SELECT COUNT(*) FROM temporal_columns)::FLOAT, 0) AS value
```
