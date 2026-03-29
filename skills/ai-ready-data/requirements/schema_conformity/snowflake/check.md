# Check: schema_conformity

Fraction of columns with correct data types — columns whose declared type matches naming conventions score as conforming.

## Context

Flags columns with overly permissive or mismatched types: VARIANT columns that don't appear to hold JSON payloads, VARCHAR columns whose names suggest IDs or timestamps, and FLOAT columns whose names suggest integer counts. Uses TRY_TO_NUMBER, TRY_TO_DATE, TRY_TO_TIMESTAMP for type checking.

A score of 1.0 means every column in the table has an appropriate declared type. Lower scores indicate columns that may need type tightening for downstream AI consumption.

## SQL

```sql
WITH declared_types AS (
    SELECT 
        table_name,
        column_name,
        data_type,
        is_nullable
    FROM {{ database }}.information_schema.columns
    WHERE table_schema = '{{ schema }}'
        AND table_name = '{{ asset }}'
),
type_violations AS (
    SELECT COUNT(*) AS cnt
    FROM declared_types
    WHERE 
        -- Flag columns with overly permissive types
        (data_type = 'VARIANT' AND column_name NOT LIKE '%JSON%' AND column_name NOT LIKE '%PAYLOAD%')
        OR (data_type = 'VARCHAR' AND column_name LIKE '%_ID' AND column_name NOT LIKE '%UUID%')
        OR (data_type = 'VARCHAR' AND (column_name LIKE '%_DATE' OR column_name LIKE '%_AT' OR column_name LIKE '%_TIME'))
        OR (data_type = 'FLOAT' AND (column_name LIKE '%_COUNT' OR column_name LIKE '%_QTY' OR column_name LIKE '%_QUANTITY'))
),
total AS (
    SELECT COUNT(*) AS cnt FROM declared_types
)
SELECT
    total.cnt - type_violations.cnt AS conforming_columns,
    total.cnt AS total_columns,
    (total.cnt - type_violations.cnt)::FLOAT / NULLIF(total.cnt::FLOAT, 0) AS value
FROM type_violations, total
```
