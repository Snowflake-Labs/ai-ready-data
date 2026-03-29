# Check: encoding_validity

Fraction of text column values free of encoding errors, garbled characters, or Unicode replacement characters.

## Context

Uses CHR(65533) for U+FFFD replacement character detection. Stripping bad characters may change string length and semantics.

## SQL

```sql
SELECT
    '{{ asset }}' AS table_name,
    '{{ column }}' AS column_name,
    COUNT(*) AS total_rows,
    SUM(CASE 
        WHEN {{ column }} NOT LIKE '%' || CHR(65533) || '%'  -- U+FFFD replacement character
            AND {{ column }} NOT LIKE '%' || CHR(0) || '%'    -- null byte
            AND REGEXP_COUNT({{ column }}, '[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F]') = 0  -- control chars
        THEN 1 ELSE 0 
    END) AS valid_rows,
    SUM(CASE 
        WHEN {{ column }} NOT LIKE '%' || CHR(65533) || '%'
            AND {{ column }} NOT LIKE '%' || CHR(0) || '%'
            AND REGEXP_COUNT({{ column }}, '[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F]') = 0
        THEN 1 ELSE 0 
    END)::FLOAT / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM {{ database }}.{{ schema }}.{{ asset }}
WHERE {{ column }} IS NOT NULL
```
