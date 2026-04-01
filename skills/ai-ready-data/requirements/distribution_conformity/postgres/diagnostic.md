# Diagnostic: distribution_conformity

Shows current vs baseline distribution statistics for drift analysis.

## Context

Returns a full statistical profile of the target column — count, nulls, mean, stddev, median, min, max, percentiles (p25, p75, p95), and IQR — alongside a drift status label. Drift status is classified as `SIGNIFICANT_DRIFT` (>2 stddevs from baseline mean), `MODERATE_DRIFT` (>1 stddev), or `STABLE`.

Use this to understand the shape of the current distribution and how far it has moved from the declared baseline.

PostgreSQL uses `percentile_cont` (exact ordered-set aggregate) instead of Snowflake's `APPROX_PERCENTILE`.

## SQL

```sql
WITH current_stats AS (
    SELECT
        '{{ column }}' AS column_name,
        COUNT(*) AS row_count,
        COUNT(*) FILTER (WHERE {{ column }} IS NULL) AS null_count,
        AVG({{ column }}) AS current_mean,
        STDDEV({{ column }}) AS current_stddev,
        percentile_cont(0.5) WITHIN GROUP (ORDER BY {{ column }}) AS current_median,
        MIN({{ column }}) AS current_min,
        MAX({{ column }}) AS current_max,
        percentile_cont(0.25) WITHIN GROUP (ORDER BY {{ column }}) AS current_p25,
        percentile_cont(0.75) WITHIN GROUP (ORDER BY {{ column }}) AS current_p75,
        percentile_cont(0.95) WITHIN GROUP (ORDER BY {{ column }}) AS current_p95
    FROM {{ schema }}.{{ asset }}
)
SELECT
    column_name,
    row_count,
    null_count,
    ROUND(current_mean::NUMERIC, 4) AS mean,
    ROUND(current_stddev::NUMERIC, 4) AS stddev,
    ROUND(current_median::NUMERIC, 4) AS median,
    ROUND(current_min::NUMERIC, 4) AS min_val,
    ROUND(current_max::NUMERIC, 4) AS max_val,
    ROUND(current_p25::NUMERIC, 4) AS p25,
    ROUND(current_p75::NUMERIC, 4) AS p75,
    ROUND(current_p95::NUMERIC, 4) AS p95,
    ROUND((current_p75 - current_p25)::NUMERIC, 4) AS iqr,
    CASE
        WHEN ABS(current_mean - {{ baseline_mean }}) / NULLIF({{ baseline_stddev }}, 0) > 2 THEN 'SIGNIFICANT_DRIFT'
        WHEN ABS(current_mean - {{ baseline_mean }}) / NULLIF({{ baseline_stddev }}, 0) > 1 THEN 'MODERATE_DRIFT'
        ELSE 'STABLE'
    END AS drift_status
FROM current_stats
```
