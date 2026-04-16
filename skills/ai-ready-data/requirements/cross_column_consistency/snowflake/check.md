# Check: cross_column_consistency

Fraction of records where logically related columns are mutually consistent per declared cross-column rules.

## Context

Template query — the caller supplies a `{{ consistency_rule }}` expression and a `{{ filter_nulls }}` predicate. Both are injected as **raw SQL**, not quoted strings.

Example consistency rules:
- `end_date >= start_date`
- `total = quantity * unit_price`
- `status <> 'SHIPPED' OR shipped_date IS NOT NULL`

`{{ filter_nulls }}` should exclude rows where nulls in the compared columns would cause misleading violations (e.g., `start_date IS NOT NULL AND end_date IS NOT NULL`). A score of 1.0 means all rows (after null filtering) satisfy the rule.

## SQL

```sql
WITH consistency_check AS (
    SELECT
        COUNT(*) AS total_rows,
        COUNT_IF(NOT ({{ consistency_rule }})) AS inconsistent_rows
    FROM {{ database }}.{{ schema }}.{{ asset }}
    WHERE {{ filter_nulls }}
)
SELECT
    inconsistent_rows,
    total_rows,
    1.0 - (inconsistent_rows::FLOAT / NULLIF(total_rows::FLOAT, 0)) AS value
FROM consistency_check
```
