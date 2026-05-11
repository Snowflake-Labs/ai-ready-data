# Check: distribution_conformity

Fraction of features whose statistical distributions conform to declared baseline distributions within tolerance thresholds.

## Context

Computes the current mean and standard deviation for the target column and compares them against the declared baseline (`baseline_mean`, `baseline_stddev`). Mean drift and stddev drift are each normalized by the baseline standard deviation, then averaged and inverted to produce a conformity score between 0 and 1.

A score of 1.0 means the column's distribution matches the baseline exactly. As either the mean or standard deviation diverges from the baseline, the score decreases toward 0.

PostgreSQL uses `percentile_cont` (exact) instead of Snowflake's `APPROX_PERCENTILE` (approximate).

## SQL

```sql
WITH current_stats AS (
    SELECT
        AVG({{ column }}) AS current_mean,
        STDDEV({{ column }}) AS current_stddev,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY {{ column }}) AS current_median,
        MIN({{ column }}) AS current_min,
        MAX({{ column }}) AS current_max,
        percentile_cont(0.25) WITHIN GROUP (ORDER BY {{ column }}) AS current_p25,
        percentile_cont(0.75) WITHIN GROUP (ORDER BY {{ column }}) AS current_p75
    FROM {{ schema }}.{{ asset }}
    WHERE {{ column }} IS NOT NULL
),
drift_score AS (
    SELECT
        ABS(current_mean - {{ baseline_mean }}) / NULLIF({{ baseline_stddev }}, 0) AS mean_drift,
        ABS(current_stddev - {{ baseline_stddev }}) / NULLIF({{ baseline_stddev }}, 0) AS stddev_drift
    FROM current_stats
)
SELECT
    ROUND(mean_drift::NUMERIC, 3) AS mean_drift,
    ROUND(stddev_drift::NUMERIC, 3) AS stddev_drift,
    GREATEST(0, 1 - (mean_drift + stddev_drift) / 2) AS value
FROM drift_score
```
