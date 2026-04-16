# Check: data_provenance

Fraction of base tables whose `COMMENT` carries provenance signal — a description longer than 20 characters that mentions a source, origin, or upstream system.

## Context

A table counts as having provenance if its comment is non-null, at least 20 characters long, and matches a provenance regex. The 20-character minimum filters out trivially short comments like "source table" that don't actually describe the upstream.

Provenance keywords are matched case-insensitively via `REGEXP_LIKE` with word-ish boundaries (`(^|\W)` prefix) so `%from%` doesn't match arbitrary prose containing those letters inside unrelated words.

Returns NULL (N/A) when the schema contains no base tables.

## SQL

```sql
WITH tables_in_scope AS (
    SELECT
        table_name,
        comment
    FROM {{ database }}.information_schema.tables
    WHERE UPPER(table_schema) = UPPER('{{ schema }}')
        AND table_type = 'BASE TABLE'
),
tables_with_provenance AS (
    SELECT *
    FROM tables_in_scope
    WHERE comment IS NOT NULL
        AND LENGTH(comment) > 20
        AND REGEXP_LIKE(
            LOWER(comment),
            '(^|\\W)(source|origin|from|upstream|loaded|extracted)(\\W|$)'
        )
)
SELECT
    (SELECT COUNT(*) FROM tables_with_provenance) AS tables_with_provenance,
    (SELECT COUNT(*) FROM tables_in_scope) AS total_tables,
    (SELECT COUNT(*) FROM tables_with_provenance)::FLOAT
        / NULLIF((SELECT COUNT(*) FROM tables_in_scope)::FLOAT, 0) AS value
```
