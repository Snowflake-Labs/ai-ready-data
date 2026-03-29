# Check: distribution_conformity

Fraction of features whose statistical distributions conform to declared baseline distributions within tolerance thresholds.

## Context

Computes the current mean and standard deviation for the target column and compares them against the declared baseline (`baseline_mean`, `baseline_stddev`). Mean drift and stddev drift are each normalized by the baseline standard deviation, then averaged and inverted to produce a conformity score between 0 and 1.

A score of 1.0 means the column's distribution matches the baseline exactly. As either the mean or standard deviation diverges from the baseline, the score decreases toward 0.

## SQL

```sql
WITH current_stats AS (
    SELECT
        AVG({{ column }}) AS current_mean,
        STDDEV({{ column }}) AS current_stddev,
        MEDIAN({{ column }}) AS current_median,
        MIN({{ column }}) AS current_min,
        MAX({{ column }}) AS current_max,
        APPROX_PERCENTILE({{ column }}, 0.25) AS current_p25,
        APPROX_PERCENTILE({{ column }}, 0.75) AS current_p75
    FROM {{ database }}.{{ schema }}.{{ asset }}
    WHERE {{ column }} IS NOT NULL
),
drift_score AS (
    SELECT
        -- Calculate normalized drift from baseline
        -- baseline values are provided as parameters
        ABS(current_mean - {{ baseline_mean }}) / NULLIF({{ baseline_stddev }}, 0) AS mean_drift,
        ABS(current_stddev - {{ baseline_stddev }}) / NULLIF({{ baseline_stddev }}, 0) AS stddev_drift
    FROM current_stats
)
SELECT
    ROUND(mean_drift, 3) AS mean_drift,
    ROUND(stddev_drift, 3) AS stddev_drift,
    -- Convert to conformity score: 1.0 = perfect conformity, 0.0 = major drift
    GREATEST(0, 1 - (mean_drift + stddev_drift) / 2) AS value
FROM drift_score
```