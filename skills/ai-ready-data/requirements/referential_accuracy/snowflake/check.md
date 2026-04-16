# Check: referential_accuracy

Fraction of non-null column values verified as present in an authoritative reference or ground-truth source.

## Context

Compares values in a source column against a reference/lookup table using a `LEFT JOIN`. Typical use cases include ZIP code validation, currency codes, country codes, and other controlled vocabularies.

NULL source values are **excluded** from both the denominator and the numerator — only rows with a value to verify are counted. If the column is expected to be NOT NULL, combine this check with `data_completeness`.

A score of 1.0 means every non-null value in the source column has a matching entry in the reference table.

Placeholders: `database`, `schema`, `asset`, `column`, `ref_namespace`, `ref_asset`, `ref_key`. `ref_namespace` may be `{database}.{schema}` or a different schema in the same database.

## SQL

```sql
WITH accuracy_check AS (
    SELECT
        COUNT(*) AS total_rows,
        COUNT_IF(ref.{{ ref_key }} IS NULL) AS unverified_rows
    FROM {{ database }}.{{ schema }}.{{ asset }} source
    LEFT JOIN {{ ref_namespace }}.{{ ref_asset }} ref
        ON source.{{ column }} = ref.{{ ref_key }}
    WHERE source.{{ column }} IS NOT NULL
)
SELECT
    unverified_rows,
    total_rows,
    1.0 - (unverified_rows::FLOAT / NULLIF(total_rows::FLOAT, 0)) AS value
FROM accuracy_check
```
