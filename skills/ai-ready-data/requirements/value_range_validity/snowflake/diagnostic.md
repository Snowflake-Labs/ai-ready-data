# Diagnostic: value_range_validity

Statistics and outliers for a numeric column to determine appropriate min/max ranges.

## Context

Returns distribution statistics including min, max, mean, median, standard deviation, and key percentiles (p1, p5, p95, p99). Use this to understand the actual data distribution before declaring valid ranges or to investigate why a check scored below 1.0.

## SQL

```sql
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
```
