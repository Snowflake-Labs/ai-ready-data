# Fix: encoding_validity

## Context

Uses CHR(65533) for U+FFFD replacement character detection. Stripping bad characters may change string length and semantics.

## SQL

### replace-encoding-errors

```sql
UPDATE {{ database }}.{{ schema }}.{{ asset }}
SET {{ column }} = REGEXP_REPLACE(
    REPLACE(
        REPLACE({{ column }}, CHR(65533), ''),
        CHR(0), ''
    ),
    '[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F]', ''
)
WHERE {{ column }} LIKE '%' || CHR(65533) || '%'
    OR {{ column }} LIKE '%' || CHR(0) || '%'
    OR REGEXP_COUNT({{ column }}, '[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F]') > 0
```
