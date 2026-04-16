# Check: distribution_conformity

Fraction (0–1) representing how closely a column's current mean and standard deviation match a declared baseline.

## Context

Computes current `AVG` and `STDDEV` of the target column, compares each against the supplied baseline (`baseline_mean`, `baseline_stddev`), normalizes the drift by the baseline standard deviation, then averages the two normalized drifts and inverts the result to produce a conformity score in `[0, 1]`.

A score of 1.0 means the column's distribution matches the baseline exactly. As either the mean or the standard deviation diverges, the score decreases toward 0. The score is clamped at 0 via `GREATEST` so extreme drift doesn't produce negative values.

Additional distributional statistics (min, max, median, p25, p75) live in `diagnostic.md` — this check emits only the fields needed to score.

## SQL

```sql
WITH current_stats AS (
    SELECT
        AVG({{ column }})    AS current_mean,
        STDDEV({{ column }}) AS current_stddev
    FROM {{ database }}.{{ schema }}.{{ asset }}
    WHERE {{ column }} IS NOT NULL
),
drift AS (
    SELECT
        ABS(current_mean   - {{ baseline_mean }})   / NULLIF({{ baseline_stddev }}, 0) AS mean_drift,
        ABS(current_stddev - {{ baseline_stddev }}) / NULLIF({{ baseline_stddev }}, 0) AS stddev_drift
    FROM current_stats
)
SELECT
    ROUND(mean_drift, 3)   AS mean_drift,
    ROUND(stddev_drift, 3) AS stddev_drift,
    GREATEST(0, 1 - (mean_drift + stddev_drift) / 2) AS value
FROM drift
```
