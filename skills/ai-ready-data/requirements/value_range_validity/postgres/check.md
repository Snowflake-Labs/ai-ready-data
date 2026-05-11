# Check: value_range_validity

Fraction of numeric column values that fall within declared valid ranges or domain boundaries.

## Context

Requires `{{ column }}`, `{{ min_value }}`, and `{{ max_value }}` parameters. Only non-null rows are evaluated — nulls are excluded from both the numerator and denominator. A score of 1.0 means every non-null value falls within the declared range.

PostgreSQL also supports native `CHECK` constraints for enforcing ranges at the schema level — see the fix for adding these after remediation.

## SQL

```sql
SELECT
    '{{ asset }}' AS table_name,
    '{{ column }}' AS column_name,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN {{ column }} >= {{ min_value }} AND {{ column }} <= {{ max_value }} THEN 1 ELSE 0 END) AS valid_rows,
    SUM(CASE WHEN {{ column }} >= {{ min_value }} AND {{ column }} <= {{ max_value }} THEN 1 ELSE 0 END)::NUMERIC
        / NULLIF(COUNT(*)::NUMERIC, 0) AS value
FROM {{ schema }}.{{ asset }}
WHERE {{ column }} IS NOT NULL
```
