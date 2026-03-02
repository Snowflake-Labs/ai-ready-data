-- diagnostic-encoding-validity.sql
-- Returns: rows with encoding issues in a text column

SELECT
    {{ key_columns }},
    {{ column }} AS problematic_value,
    LENGTH({{ column }}) AS length,
    CASE
        WHEN {{ column }} LIKE '%' || CHR(65533) || '%' THEN 'Contains replacement character (U+FFFD)'
        WHEN {{ column }} LIKE '%' || CHR(0) || '%' THEN 'Contains null byte'
        WHEN REGEXP_COUNT({{ column }}, '[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F]') > 0 THEN 'Contains control characters'
        ELSE 'Unknown encoding issue'
    END AS issue
FROM {{ database }}.{{ schema }}.{{ asset }}
WHERE {{ column }} IS NOT NULL
    AND (
        {{ column }} LIKE '%' || CHR(65533) || '%'
        OR {{ column }} LIKE '%' || CHR(0) || '%'
        OR REGEXP_COUNT({{ column }}, '[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F]') > 0
    )
LIMIT 100
