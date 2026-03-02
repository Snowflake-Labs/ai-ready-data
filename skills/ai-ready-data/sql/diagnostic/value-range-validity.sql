-- diagnostic-value-range-validity.sql
-- Returns: statistics and outliers for a numeric column
-- Use to determine appropriate min/max ranges

SELECT
    '{{ asset }}' AS table_name,
    '{{ field }}' AS column_name,
    COUNT(*) AS total_rows,
    COUNT({{ field }}) AS non_null_rows,
    MIN({{ field }}) AS min_value,
    MAX({{ field }}) AS max_value,
    AVG({{ field }}) AS avg_value,
    MEDIAN({{ field }}) AS median_value,
    STDDEV({{ field }}) AS stddev_value,
    APPROX_PERCENTILE({{ field }}, 0.01) AS p1,
    APPROX_PERCENTILE({{ field }}, 0.05) AS p5,
    APPROX_PERCENTILE({{ field }}, 0.95) AS p95,
    APPROX_PERCENTILE({{ field }}, 0.99) AS p99
FROM {{ container }}.{{ namespace }}.{{ asset }}
