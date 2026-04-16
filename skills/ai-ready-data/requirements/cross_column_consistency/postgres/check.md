# Check: cross_column_consistency

Fraction of records where logically related columns are mutually consistent per declared cross-column rules.

## Context

This is a template query — the agent must generate a `consistency_rule` and `filter_nulls` expression for each use case. These are injected as raw SQL expressions, not quoted strings.

Example consistency rules:
- `end_date >= start_date`
- `total = quantity * unit_price`
- `status = 'SHIPPED' AND shipped_date IS NOT NULL`

The `filter_nulls` predicate should exclude rows where null values in the checked columns would cause misleading violations (e.g., `column1 IS NOT NULL AND column2 IS NOT NULL`).

Returns a float 0–1 representing the fraction of consistent records. A value of 1.0 means all rows (after null filtering) satisfy the rule.

## SQL

```sql
WITH consistency_check AS (
    SELECT
        COUNT(*) AS total_rows,
        COUNT(*) FILTER (WHERE NOT ({{ consistency_rule }})) AS inconsistent_rows
    FROM {{ schema }}.{{ asset }}
    WHERE {{ filter_nulls }}
)
SELECT
    inconsistent_rows,
    total_rows,
    1.0 - (inconsistent_rows::NUMERIC / NULLIF(total_rows::NUMERIC, 0)) AS value
FROM consistency_check
```
