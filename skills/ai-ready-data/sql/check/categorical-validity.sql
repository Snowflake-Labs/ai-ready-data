-- check-categorical-validity.sql
-- Returns: value (float 0-1) - fraction of values in allowed set
-- Direction: gte (higher is better)
-- Note: {{ allowed_values }} should be a comma-separated list like 'A','B','C'

SELECT
    '{{ asset }}' AS table_name,
    '{{ field }}' AS column_name,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN {{ field }} IN ({{ allowed_values }}) THEN 1 ELSE 0 END) AS valid_rows,
    SUM(CASE WHEN {{ field }} IN ({{ allowed_values }}) THEN 1 ELSE 0 END)::FLOAT 
        / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM {{ container }}.{{ namespace }}.{{ asset }}
WHERE {{ field }} IS NOT NULL
