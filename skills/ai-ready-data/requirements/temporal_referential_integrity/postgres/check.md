# Check: temporal_referential_integrity

Fraction of records with valid, non-null event timestamps traceable to source system origination time.

## Context

Validates that timestamp values in `{{ timestamp_column }}` are non-null, not in the future, and not before 1900-01-01. Records outside this range are treated as invalid. A score of 1.0 means every row has a plausible event timestamp.

PostgreSQL timestamp comparison uses `TIMESTAMP '1900-01-01'` literal syntax.

## SQL

```sql
WITH timestamp_check AS (
    SELECT
        COUNT(*) AS total_rows,
        COUNT(*) FILTER (WHERE
            {{ timestamp_column }} IS NOT NULL
            AND {{ timestamp_column }} <= CURRENT_TIMESTAMP
            AND {{ timestamp_column }} >= TIMESTAMP '1900-01-01'
        ) AS valid_timestamp_rows
    FROM {{ schema }}.{{ asset }}
)
SELECT
    valid_timestamp_rows,
    total_rows,
    valid_timestamp_rows::NUMERIC / NULLIF(total_rows::NUMERIC, 0) AS value
FROM timestamp_check
```
