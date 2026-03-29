# Check: referential_accuracy

Fraction of column values verified as correct against an authoritative reference or ground-truth source.

## Context

Compares values in a source column against a reference/lookup table using a LEFT JOIN. Common use cases include ZIP code validation, currency code validation, country codes, and similar lookups.

A score of 1.0 means every non-null value in the source column has a matching entry in the reference table. Rows where the source value is non-null but no match exists in the reference table count as unverified.

Placeholders: `database`, `schema`, `asset`, `column`, `ref_namespace`, `ref_asset`, `ref_column`.

## SQL

```sql
-- check-referential-accuracy.sql
-- Checks fraction of values verified against an authoritative reference
-- Returns: value (float 0-1) - fraction of values verified against reference (1.0 = all match)

-- This check compares values against a reference/lookup table
-- Use cases: ZIP code validation, currency code validation, country codes, etc.

WITH accuracy_check AS (
    SELECT
        COUNT(*) AS total_rows,
        COUNT_IF(
            source.{{ column }} IS NOT NULL 
            AND ref.{{ ref_column }} IS NULL
        ) AS unverified_rows
    FROM {{ database }}.{{ schema }}.{{ asset }} source
    LEFT JOIN {{ database }}.{{ ref_namespace }}.{{ ref_asset }} ref
        ON source.{{ column }} = ref.{{ ref_column }}
)
SELECT
    unverified_rows,
    total_rows,
    1.0 - (unverified_rows::FLOAT / NULLIF(total_rows::FLOAT, 0)) AS value
FROM accuracy_check
```
