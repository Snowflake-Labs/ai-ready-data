# Check: temporal_referential_integrity

Fraction of rows whose `{{ timestamp_column }}` is non-null, not in the future, and not before 1900-01-01.

## Context

Validates that timestamp values are plausible. A score of 1.0 means every row has a valid event timestamp. Rows failing any of the three conditions — NULL, future-dated, or pre-1900 — are treated as invalid.

## SQL

```sql
WITH timestamp_check AS (
    SELECT
        COUNT(*) AS total_rows,
        COUNT_IF(
            {{ timestamp_column }} IS NOT NULL
            AND {{ timestamp_column }} <= CURRENT_TIMESTAMP()
            AND {{ timestamp_column }} >= '1900-01-01'::TIMESTAMP
        ) AS valid_timestamp_rows
    FROM {{ database }}.{{ schema }}.{{ asset }}
)
SELECT
    valid_timestamp_rows,
    total_rows,
    valid_timestamp_rows::FLOAT / NULLIF(total_rows::FLOAT, 0) AS value
FROM timestamp_check
```
