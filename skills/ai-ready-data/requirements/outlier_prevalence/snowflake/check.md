# Check: outlier_prevalence

Fraction of records containing values flagged as statistical outliers beyond declared distance thresholds.

## Context

Uses z-score analysis against a configurable `stddev_threshold` to classify rows as outliers. Only non-NULL values in the target column are evaluated. A score of 1.0 means no rows exceed the threshold; lower scores indicate a higher fraction of outliers.

Placeholders: `database`, `schema`, `asset`, `column`, `stddev_threshold`.

## SQL

```sql
-- check-outlier-prevalence.sql
-- Checks fraction of records containing statistical outliers (beyond N standard deviations)
-- Returns: value (float 0-1) - fraction of rows within expected range (1.0 = no outliers)

WITH stats AS (
    SELECT
        AVG({{ column }}) AS mean_val,
        STDDEV({{ column }}) AS stddev_val
    FROM {{ database }}.{{ schema }}.{{ asset }}
    WHERE {{ column }} IS NOT NULL
),
outlier_check AS (
    SELECT
        COUNT(*) AS total_rows,
        COUNT_IF(
            ABS(t.{{ column }} - s.mean_val) > ({{ stddev_threshold }} * s.stddev_val)
        ) AS outlier_rows
    FROM {{ database }}.{{ schema }}.{{ asset }} t
    CROSS JOIN stats s
    WHERE t.{{ column }} IS NOT NULL
)
SELECT
    outlier_rows,
    total_rows,
    1.0 - (outlier_rows::FLOAT / NULLIF(total_rows::FLOAT, 0)) AS value
FROM outlier_check
```
