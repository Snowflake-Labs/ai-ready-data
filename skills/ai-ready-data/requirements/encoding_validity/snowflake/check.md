# Check: encoding_validity

Fraction of text column values free of encoding errors, garbled characters, or Unicode replacement characters.

## Context

Flags a value as invalid if it contains any of:

- U+FFFD (`CHR(65533)`) — the Unicode replacement character, typically introduced during a failed decode.
- U+0000 (`CHR(0)`) — a null byte, not legal inside a Snowflake `TEXT`/`VARCHAR` but occasionally present after botched imports.
- C0 control characters (U+0000–U+001F, excluding TAB, LF, CR) — matched by the regex character class `[\x00-\x08\x0B\x0C\x0E-\x1F]`.

Stripping bad characters may change string length and semantics — prefer fixing upstream ingestion. NULL values are excluded from the denominator; only non-null values are tested.

## SQL

```sql
WITH col_check AS (
    SELECT
        COUNT(*) AS total_rows,
        COUNT_IF(
            POSITION(CHR(65533) IN {{ column }}) = 0
            AND POSITION(CHR(0) IN {{ column }}) = 0
            AND REGEXP_COUNT({{ column }}, '[\x00-\x08\x0B\x0C\x0E-\x1F]') = 0
        ) AS valid_rows
    FROM {{ database }}.{{ schema }}.{{ asset }}
    WHERE {{ column }} IS NOT NULL
)
SELECT
    '{{ asset }}' AS table_name,
    '{{ column }}' AS column_name,
    total_rows,
    valid_rows,
    valid_rows::FLOAT / NULLIF(total_rows::FLOAT, 0) AS value
FROM col_check
```
