-- check-value-range-validity.sql
-- Returns: value (float 0-1) - fraction of numeric values within expected ranges
-- Direction: gte (higher is better)
-- Note: Requires {{ field }}, {{ min_value }}, {{ max_value }} parameters

SELECT
    '{{ asset }}' AS table_name,
    '{{ field }}' AS column_name,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN {{ field }} >= {{ min_value }} AND {{ field }} <= {{ max_value }} THEN 1 ELSE 0 END) AS valid_rows,
    SUM(CASE WHEN {{ field }} >= {{ min_value }} AND {{ field }} <= {{ max_value }} THEN 1 ELSE 0 END)::FLOAT 
        / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM {{ container }}.{{ namespace }}.{{ asset }}
WHERE {{ field }} IS NOT NULL
