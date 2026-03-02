-- diagnostic-categorical-validity.sql
-- Returns: distinct values and their counts for a categorical column
-- Use to discover the actual value distribution

SELECT
    {{ field }} AS category_value,
    COUNT(*) AS row_count,
    COUNT(*)::FLOAT / SUM(COUNT(*)) OVER () AS pct_of_total
FROM {{ container }}.{{ namespace }}.{{ asset }}
WHERE {{ field }} IS NOT NULL
GROUP BY {{ field }}
ORDER BY row_count DESC
LIMIT 100
