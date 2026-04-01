# Check: outlier_prevalence

Fraction of records containing values flagged as statistical outliers beyond declared distance thresholds.

## Context

Uses z-score analysis against a configurable `stddev_threshold` to classify rows as outliers. Only non-NULL values in the target column are evaluated. A score of 1.0 means no rows exceed the threshold; lower scores indicate a higher fraction of outliers.

Placeholders: `schema`, `asset`, `column`, `stddev_threshold`.

## SQL

```sql
WITH stats AS (
    SELECT
        AVG({{ column }}) AS mean_val,
        STDDEV({{ column }}) AS stddev_val
    FROM {{ schema }}.{{ asset }}
    WHERE {{ column }} IS NOT NULL
),
outlier_check AS (
    SELECT
        COUNT(*) AS total_rows,
        COUNT(*) FILTER (WHERE
            ABS(t.{{ column }} - s.mean_val) > ({{ stddev_threshold }} * s.stddev_val)
        ) AS outlier_rows
    FROM {{ schema }}.{{ asset }} t
    CROSS JOIN stats s
    WHERE t.{{ column }} IS NOT NULL
)
SELECT
    outlier_rows,
    total_rows,
    1.0 - (outlier_rows::NUMERIC / NULLIF(total_rows::NUMERIC, 0)) AS value
FROM outlier_check
```
