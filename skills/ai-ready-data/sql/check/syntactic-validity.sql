-- check-syntactic-validity.sql
-- Returns: value (float 0-1) - fraction of JSON/structured fields that parse correctly
-- Direction: gte (higher is better)
-- Use for VARIANT columns or VARCHAR columns containing JSON

SELECT
    '{{ asset }}' AS table_name,
    '{{ column }}' AS column_name,
    COUNT(*) AS total_rows,
    SUM(CASE 
        WHEN TRY_PARSE_JSON({{ column }}) IS NOT NULL OR {{ column }} IS NULL
        THEN 1 ELSE 0 
    END) AS valid_rows,
    SUM(CASE 
        WHEN TRY_PARSE_JSON({{ column }}) IS NOT NULL OR {{ column }} IS NULL
        THEN 1 ELSE 0 
    END)::FLOAT / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM {{ database }}.{{ schema }}.{{ asset }}
