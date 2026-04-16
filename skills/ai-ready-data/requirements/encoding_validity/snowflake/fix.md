# Fix: encoding_validity

Strip invalid encoding artifacts (U+FFFD replacement characters, null bytes, and C0 control characters) from a text column.

## Context

The regex character class `[\x00-\x08\x0B\x0C\x0E-\x1F]` matches C0 control characters other than TAB (U+0009), LF (U+000A), and CR (U+000D), which are typically legitimate. The regex uses single-backslash escapes to match the form used in `check.md`; Snowflake interprets `\x..` inside a regex pattern literal as a hex escape.

Stripping bad characters may change string length and semantics — if upstream ingestion is fixable, prefer repairing the source so subsequent loads don't reintroduce these characters. The `POSITION(...)` predicates in the `WHERE` clause restrict the UPDATE to only affected rows, which keeps the statement cheap on large tables and avoids touching `last_altered` on clean rows.

## Fix: Replace encoding errors

```sql
UPDATE {{ database }}.{{ schema }}.{{ asset }}
SET {{ column }} = REGEXP_REPLACE(
    REPLACE({{ column }}, CHR(65533), ''),
    '[\x00-\x08\x0B\x0C\x0E-\x1F]', ''
)
WHERE POSITION(CHR(65533) IN {{ column }}) > 0
    OR REGEXP_COUNT({{ column }}, '[\x00-\x08\x0B\x0C\x0E-\x1F]') > 0
```
