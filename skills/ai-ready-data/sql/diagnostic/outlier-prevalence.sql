-- diagnostic-outlier-prevalence.sql
-- Lists records with values flagged as statistical outliers
-- Returns: outlier records with z-score details

WITH stats AS (
    SELECT
        AVG({{ column }}) AS mean_val,
        STDDEV({{ column }}) AS stddev_val
    FROM {{ database }}.{{ schema }}.{{ asset }}
    WHERE {{ column }} IS NOT NULL
)
SELECT
    {{ key_columns }},
    t.{{ column }} AS value,
    s.mean_val AS column_mean,
    s.stddev_val AS column_stddev,
    ROUND((t.{{ column }} - s.mean_val) / NULLIF(s.stddev_val, 0), 2) AS z_score,
    CASE
        WHEN (t.{{ column }} - s.mean_val) / NULLIF(s.stddev_val, 0) > {{ stddev_threshold }} THEN 'HIGH_OUTLIER'
        WHEN (t.{{ column }} - s.mean_val) / NULLIF(s.stddev_val, 0) < -{{ stddev_threshold }} THEN 'LOW_OUTLIER'
        ELSE 'NORMAL'
    END AS outlier_type
FROM {{ database }}.{{ schema }}.{{ asset }} t
CROSS JOIN stats s
WHERE t.{{ column }} IS NOT NULL
    AND ABS(t.{{ column }} - s.mean_val) > ({{ stddev_threshold }} * s.stddev_val)
ORDER BY ABS((t.{{ column }} - s.mean_val) / NULLIF(s.stddev_val, 0)) DESC
LIMIT 100
