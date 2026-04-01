# Diagnostic: encoding_validity

Rows with encoding issues in a text column.

## Context

Returns rows containing Unicode replacement characters (U+FFFD) or control characters. PostgreSQL rejects invalid UTF-8 at ingestion, so most encoding issues manifest as replacement characters inserted by upstream systems or control characters embedded in text fields.

## SQL

```sql
SELECT
    {{ key_columns }},
    {{ column }} AS problematic_value,
    LENGTH({{ column }}) AS length,
    CASE
        WHEN {{ column }} LIKE '%' || CHR(65533) || '%' THEN 'Contains replacement character (U+FFFD)'
        WHEN {{ column }} ~ '[\x01-\x08\x0B\x0C\x0E-\x1F]' THEN 'Contains control characters'
        ELSE 'Unknown encoding issue'
    END AS issue
FROM {{ schema }}.{{ asset }}
WHERE {{ column }} IS NOT NULL
    AND (
        {{ column }} LIKE '%' || CHR(65533) || '%'
        OR {{ column }} ~ '[\x01-\x08\x0B\x0C\x0E-\x1F]'
    )
LIMIT 100
```
