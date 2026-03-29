# Diagnostic: syntactic_validity

Rows where JSON parsing fails, showing the invalid values and their lengths.

## Context

Returns up to 100 rows where `TRY_PARSE_JSON` returns NULL on a non-null value, indicating malformed JSON. The `value_preview` column truncates to 200 characters for readability. Use the key columns to locate specific failing records for manual inspection or targeted remediation.

## SQL

```sql
SELECT
    {{ key_columns }},
    {{ column }} AS invalid_value,
    LEFT({{ column }}, 200) AS value_preview,
    LENGTH({{ column }}) AS length
FROM {{ database }}.{{ schema }}.{{ asset }}
WHERE {{ column }} IS NOT NULL
    AND TRY_PARSE_JSON({{ column }}) IS NULL
LIMIT 100
```