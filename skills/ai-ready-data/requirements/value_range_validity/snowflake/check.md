# Check: value_range_validity

Fraction of numeric column values that fall within declared valid ranges or domain boundaries.

## Context

Requires `{{ column }}`, `{{ min_value }}`, and `{{ max_value }}` parameters. Only non-null rows are evaluated — nulls are excluded from both the numerator and denominator. A score of 1.0 means every non-null value falls within the declared inclusive range `[min_value, max_value]`.

## SQL

```sql
WITH col_check AS (
    SELECT
        COUNT(*) AS total_rows,
        COUNT_IF({{ column }} BETWEEN {{ min_value }} AND {{ max_value }}) AS valid_rows
    FROM {{ database }}.{{ schema }}.{{ asset }}
    WHERE {{ column }} IS NOT NULL
)
SELECT
    '{{ asset }}' AS table_name,
    '{{ column }}' AS column_name,
    total_rows,
    valid_rows,
    valid_rows::FLOAT / NULLIF(total_rows::FLOAT, 0) AS value
FROM col_check
```
