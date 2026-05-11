# Check: business_glossary_linkage

Fraction of columns linked to a business glossary or authoritative term definition.

## Context

PostgreSQL has no native tagging system like Snowflake's `tag_references`. Business glossary linkage is detected through two signals:

1. **Security labels** (`pg_seclabel`) — if your organization uses security labels to attach glossary terms to columns, these are checked as the primary structured signal.
2. **Column comments** (>20 characters via `col_description()`) — secondary signal indicating at least some documentation effort with a meaningful description.

A column counts as linked if it has any column-level security label OR a comment longer than 20 characters. The 20-character threshold filters out trivial comments like "ID" or "name" that don't constitute a real glossary definition.

Security labels require a label provider to be loaded (e.g., `sepgsql`). If no provider is configured, only the comment-based signal will produce matches.

## SQL

```sql
WITH columns_in_scope AS (
    SELECT
        c.oid AS table_oid,
        c.relname AS table_name,
        a.attname AS column_name,
        a.attnum
    FROM pg_attribute a
    JOIN pg_class c ON c.oid = a.attrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
      AND c.relkind = 'r'
      AND a.attnum > 0
      AND NOT a.attisdropped
),
labeled_columns AS (
    SELECT DISTINCT
        sl.objoid AS table_oid,
        sl.objsubid AS attnum
    FROM pg_seclabel sl
    WHERE sl.classoid = 'pg_class'::regclass
      AND sl.objsubid > 0
)
SELECT
    COUNT(*) FILTER (
        WHERE lc.attnum IS NOT NULL
           OR (col_description(cs.table_oid, cs.attnum) IS NOT NULL
               AND LENGTH(col_description(cs.table_oid, cs.attnum)) > 20)
    ) AS columns_with_glossary,
    COUNT(*) AS total_columns,
    COUNT(*) FILTER (
        WHERE lc.attnum IS NOT NULL
           OR (col_description(cs.table_oid, cs.attnum) IS NOT NULL
               AND LENGTH(col_description(cs.table_oid, cs.attnum)) > 20)
    )::NUMERIC / NULLIF(COUNT(*)::NUMERIC, 0) AS value
FROM columns_in_scope cs
LEFT JOIN labeled_columns lc
    ON cs.table_oid = lc.table_oid
   AND cs.attnum = lc.attnum
```
