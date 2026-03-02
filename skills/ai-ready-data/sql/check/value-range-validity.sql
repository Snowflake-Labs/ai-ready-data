-- check-value-range-validity.sql
-- Returns: value (float 0-1) - fraction of numeric values within expected ranges
-- Direction: gte (higher is better)
-- Note: Requires {{ column }}, {{ min_value }}, {{ max_value }} parameters

SELECT
    '{{ asset }}' AS table_name,
    '{{ column }}' AS column_name,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN {{ column }} >= {{ min_value }} AND {{ column }} <= {{ max_value }} THEN 1 ELSE 0 END) AS valid_rows,
    SUM(CASE WHEN {{ column }} >= {{ min_value }} AND {{ column }} <= {{ max_value }} THEN 1 ELSE 0 END)::FLOAT 
        / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM {{ database }}.{{ schema }}.{{ asset }}
WHERE {{ column }} IS NOT NULL
