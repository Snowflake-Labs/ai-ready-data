# Fix: encoding_validity

## Context

Replaces Unicode replacement characters (U+FFFD) and strips control characters from text values. PostgreSQL's `regexp_replace` supports global replacement with the `'g'` flag. Stripping bad characters may change string length and semantics.

## SQL

### replace-encoding-errors

```sql
UPDATE {{ schema }}.{{ asset }}
SET {{ column }} = regexp_replace(
    REPLACE({{ column }}, CHR(65533), ''),
    '[\x01-\x08\x0B\x0C\x0E-\x1F]', '', 'g'
)
WHERE {{ column }} LIKE '%' || CHR(65533) || '%'
    OR {{ column }} ~ '[\x01-\x08\x0B\x0C\x0E-\x1F]'
```
