# Check: outlier_prevalence

Fraction of non-null rows whose target-column value is **within** the configured z-score threshold — i.e., not flagged as an outlier.

## Context

Computes mean and standard deviation on non-null values in a CTE, then re-scans the table to count rows whose value is within `{{ stddev_threshold }}` standard deviations of the mean. A score of 1.0 means no outliers; lower scores indicate a higher fraction of rows beyond the threshold.

Placeholders: `database`, `schema`, `asset`, `column`, `stddev_threshold`.

## SQL

```sql
WITH stats AS (
    SELECT
        AVG({{ column }})    AS mean_val,
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
