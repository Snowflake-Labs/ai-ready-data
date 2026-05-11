# Check: schema_conformity

Fraction of columns with correct data types — columns whose declared type matches naming conventions score as conforming.

## Context

Flags columns with overly permissive or mismatched types: JSONB columns that don't appear to hold JSON payloads, `character varying` columns whose names suggest IDs or timestamps, and `double precision`/`real` columns whose names suggest integer counts. PostgreSQL reports types in lowercase via `information_schema` (e.g., `character varying`, `jsonb`, `double precision`, `integer`).

A score of 1.0 means every column in the table has an appropriate declared type. Lower scores indicate columns that may need type tightening for downstream AI consumption.

## SQL

```sql
WITH declared_types AS (
    SELECT
        table_name,
        column_name,
        data_type,
        is_nullable
    FROM information_schema.columns
    WHERE table_schema = '{{ schema }}'
        AND table_name = '{{ asset }}'
),
type_violations AS (
    SELECT COUNT(*) AS cnt
    FROM declared_types
    WHERE
        (data_type = 'jsonb' AND column_name NOT LIKE '%json%' AND column_name NOT LIKE '%payload%')
        OR (data_type = 'character varying' AND column_name LIKE '%\_id' AND column_name NOT LIKE '%uuid%')
        OR (data_type = 'character varying' AND (column_name LIKE '%\_date' OR column_name LIKE '%\_at' OR column_name LIKE '%\_time'))
        OR (data_type IN ('double precision', 'real') AND (column_name LIKE '%\_count' OR column_name LIKE '%\_qty' OR column_name LIKE '%\_quantity'))
),
total AS (
    SELECT COUNT(*) AS cnt FROM declared_types
)
SELECT
    total.cnt - type_violations.cnt AS conforming_columns,
    total.cnt AS total_columns,
    (total.cnt - type_violations.cnt)::NUMERIC / NULLIF(total.cnt::NUMERIC, 0) AS value
FROM type_violations, total
```
