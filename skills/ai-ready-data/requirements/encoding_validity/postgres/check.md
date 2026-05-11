# Check: encoding_validity

Fraction of text column values free of encoding errors, garbled characters, or Unicode replacement characters.

## Context

PostgreSQL stores text as UTF-8 by default and rejects invalid byte sequences at ingestion time (unlike Snowflake which may silently accept them). However, data may still contain Unicode replacement characters (U+FFFD), null bytes, or control characters that were valid UTF-8 but represent encoding issues upstream.

Uses `CHR(65533)` for U+FFFD replacement character detection. PostgreSQL does not allow null bytes (`\0`) in text columns, so that check is included for completeness but will rarely match.

## SQL

```sql
SELECT
    '{{ asset }}' AS table_name,
    '{{ column }}' AS column_name,
    COUNT(*) AS total_rows,
    SUM(CASE
        WHEN {{ column }} NOT LIKE '%' || CHR(65533) || '%'
            AND {{ column }} !~ '[\x01-\x08\x0B\x0C\x0E-\x1F]'
        THEN 1 ELSE 0
    END) AS valid_rows,
    SUM(CASE
        WHEN {{ column }} NOT LIKE '%' || CHR(65533) || '%'
            AND {{ column }} !~ '[\x01-\x08\x0B\x0C\x0E-\x1F]'
        THEN 1 ELSE 0
    END)::NUMERIC / NULLIF(COUNT(*)::NUMERIC, 0) AS value
FROM {{ schema }}.{{ asset }}
WHERE {{ column }} IS NOT NULL
```
