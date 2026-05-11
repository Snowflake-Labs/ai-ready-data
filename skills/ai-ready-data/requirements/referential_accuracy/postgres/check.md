# Check: referential_accuracy

Fraction of column values verified as correct against an authoritative reference or ground-truth source.

## Context

Compares values in a source column against a reference/lookup table using a LEFT JOIN. Common use cases include ZIP code validation, currency code validation, country codes, and similar lookups.

A score of 1.0 means every non-null value in the source column has a matching entry in the reference table. Rows where the source value is non-null but no match exists in the reference table count as unverified.

Placeholders: `schema`, `asset`, `column`, `ref_schema`, `ref_asset`, `ref_column`.

## SQL

```sql
WITH accuracy_check AS (
    SELECT
        COUNT(*) AS total_rows,
        COUNT(*) FILTER (WHERE
            source.{{ column }} IS NOT NULL
            AND ref.{{ ref_column }} IS NULL
        ) AS unverified_rows
    FROM {{ schema }}.{{ asset }} source
    LEFT JOIN {{ ref_schema }}.{{ ref_asset }} ref
        ON source.{{ column }} = ref.{{ ref_column }}
)
SELECT
    unverified_rows,
    total_rows,
    1.0 - (unverified_rows::NUMERIC / NULLIF(total_rows::NUMERIC, 0)) AS value
FROM accuracy_check
```
