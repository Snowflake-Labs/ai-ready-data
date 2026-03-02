-- diagnostic-syntactic-validity.sql
-- Returns: rows where JSON parsing fails

SELECT
    {{ key_columns }},
    {{ field }} AS invalid_value,
    LEFT({{ field }}, 200) AS value_preview,
    LENGTH({{ field }}) AS length
FROM {{ container }}.{{ namespace }}.{{ asset }}
WHERE {{ field }} IS NOT NULL
    AND TRY_PARSE_JSON({{ field }}) IS NULL
LIMIT 100
