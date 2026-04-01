# Diagnostic: value_range_validity

Statistics and outliers for a numeric column to determine appropriate min/max ranges.

## Context

Returns distribution statistics including min, max, mean, median, standard deviation, and key percentiles (p1, p5, p95, p99). Use this to understand the actual data distribution before declaring valid ranges or to investigate why a check scored below 1.0.

PostgreSQL uses `percentile_cont` as an ordered-set aggregate (not an approximate function like Snowflake's `APPROX_PERCENTILE`). Results are exact but may be slower on very large tables.

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
    percentile_cont(0.5) WITHIN GROUP (ORDER BY {{ column }}) AS median_value,
    STDDEV({{ column }}) AS stddev_value,
    percentile_cont(0.01) WITHIN GROUP (ORDER BY {{ column }}) AS p1,
    percentile_cont(0.05) WITHIN GROUP (ORDER BY {{ column }}) AS p5,
    percentile_cont(0.95) WITHIN GROUP (ORDER BY {{ column }}) AS p95,
    percentile_cont(0.99) WITHIN GROUP (ORDER BY {{ column }}) AS p99
FROM {{ schema }}.{{ asset }}
```
