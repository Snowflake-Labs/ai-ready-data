-- diagnostic-syntactic-validity.sql
-- Returns: rows where JSON parsing fails

SELECT
    {{ key_columns }},
    {{ column }} AS invalid_value,
    LEFT({{ column }}, 200) AS value_preview,
    LENGTH({{ column }}) AS length
FROM {{ database }}.{{ schema }}.{{ asset }}
WHERE {{ column }} IS NOT NULL
    AND TRY_PARSE_JSON({{ column }}) IS NULL
LIMIT 100
