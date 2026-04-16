# Diagnostic: categorical_validity

Distinct value distribution for a categorical column.

## Context

Shows every distinct value in the column with its row count and percentage of total. Use this to discover the actual value distribution before defining or updating the allowed values list. Capped at 100 distinct values — if the column has more, it may not be truly categorical.

Values not in the expected allowed set are candidates for cleanup. Common patterns: trailing whitespace, case inconsistencies, legacy codes that were replaced but never backfilled.

## SQL

```sql
SELECT
    {{ column }} AS category_value,
    COUNT(*) AS row_count,
    COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER () AS pct_of_total
FROM {{ schema }}.{{ asset }}
WHERE {{ column }} IS NOT NULL
GROUP BY {{ column }}
ORDER BY row_count DESC
LIMIT 100
```
