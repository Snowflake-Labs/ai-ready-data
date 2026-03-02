-- diagnostic-encoding-validity.sql
-- Returns: rows with encoding issues in a text column

SELECT
    {{ key_columns }},
    {{ field }} AS problematic_value,
    LENGTH({{ field }}) AS length,
    CASE
        WHEN {{ field }} LIKE '%' || CHR(65533) || '%' THEN 'Contains replacement character (U+FFFD)'
        WHEN {{ field }} LIKE '%' || CHR(0) || '%' THEN 'Contains null byte'
        WHEN REGEXP_COUNT({{ field }}, '[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F]') > 0 THEN 'Contains control characters'
        ELSE 'Unknown encoding issue'
    END AS issue
FROM {{ container }}.{{ namespace }}.{{ asset }}
WHERE {{ field }} IS NOT NULL
    AND (
        {{ field }} LIKE '%' || CHR(65533) || '%'
        OR {{ field }} LIKE '%' || CHR(0) || '%'
        OR REGEXP_COUNT({{ field }}, '[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F]') > 0
    )
LIMIT 100
