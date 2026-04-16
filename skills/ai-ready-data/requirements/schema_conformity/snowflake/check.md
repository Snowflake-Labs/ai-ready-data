# Check: schema_conformity

Binary conformity score for a single column — does the declared physical type match the column's name-implied semantic role?

## Context

This is a column-scoped check. It flags a column as non-conforming when any of these mismatches hold:

- `VARIANT` column without a JSON/payload name hint.
- `TEXT`/`VARCHAR`/`STRING` column whose name ends in `_id` / `_key` / `_date` / `_at` / `_time` (but isn't a UUID-named ID).
- `FLOAT`/`DOUBLE`/`REAL` column whose name ends in `_count` / `_qty` / `_quantity`.

Pattern matching uses `REGEXP_LIKE` with anchored underscores so literal `_` separators don't get swallowed by LIKE's single-char wildcard. Snowflake normalizes unquoted types in `information_schema.columns.data_type` — `VARCHAR` is reported as `TEXT`, so all common string aliases are included.

Returns `1.0` when the column is conforming, `0.0` when it is not. Returns NULL when the column does not exist in the target schema (treat as N/A by the orchestrator).

## SQL

```sql
WITH col AS (
    SELECT
        data_type,
        column_name
    FROM {{ database }}.information_schema.columns
    WHERE UPPER(table_schema) = UPPER('{{ schema }}')
      AND UPPER(table_name)   = UPPER('{{ asset }}')
      AND UPPER(column_name)  = UPPER('{{ column }}')
)
SELECT
    '{{ asset }}'  AS table_name,
    '{{ column }}' AS column_name,
    data_type,
    CASE
        WHEN data_type = 'VARIANT'
             AND NOT REGEXP_LIKE(LOWER(column_name), '.*(json|payload).*')
            THEN 0.0
        WHEN UPPER(data_type) IN ('TEXT','VARCHAR','STRING')
             AND REGEXP_LIKE(LOWER(column_name), '.*(_id$|_key$|_date$|_at$|_time$)')
             AND NOT REGEXP_LIKE(LOWER(column_name), '.*uuid.*')
            THEN 0.0
        WHEN UPPER(data_type) IN ('FLOAT','DOUBLE','REAL')
             AND REGEXP_LIKE(LOWER(column_name), '.*(_count$|_qty$|_quantity$)')
            THEN 0.0
        ELSE 1.0
    END AS value
FROM col
```
