-- diagnostic-value-range-validity.sql
-- Returns: statistics and outliers for a numeric column
-- Use to determine appropriate min/max ranges

SELECT
    '{{ asset }}' AS table_name,
    '{{ column }}' AS column_name,
    COUNT(*) AS total_rows,
    COUNT({{ column }}) AS non_null_rows,
    MIN({{ column }}) AS min_value,
    MAX({{ column }}) AS max_value,
    AVG({{ column }}) AS avg_value,
    MEDIAN({{ column }}) AS median_value,
    STDDEV({{ column }}) AS stddev_value,
    APPROX_PERCENTILE({{ column }}, 0.01) AS p1,
    APPROX_PERCENTILE({{ column }}, 0.05) AS p5,
    APPROX_PERCENTILE({{ column }}, 0.95) AS p95,
    APPROX_PERCENTILE({{ column }}, 0.99) AS p99
FROM {{ database }}.{{ schema }}.{{ asset }}
