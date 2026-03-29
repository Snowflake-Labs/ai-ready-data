-- diagnostic-categorical-validity.sql
-- Returns: distinct values and their counts for a categorical column
-- Use to discover the actual value distribution

SELECT
    {{ column }} AS category_value,
    COUNT(*) AS row_count,
    COUNT(*)::FLOAT / SUM(COUNT(*)) OVER () AS pct_of_total
FROM {{ database }}.{{ schema }}.{{ asset }}
WHERE {{ column }} IS NOT NULL
GROUP BY {{ column }}
ORDER BY row_count DESC
LIMIT 100
