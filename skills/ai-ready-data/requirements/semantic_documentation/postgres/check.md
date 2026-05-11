# Check: semantic_documentation

Fraction of columns with machine-readable semantic descriptions (comments).

## Context

PostgreSQL does not have Snowflake's semantic views. The only check variant is **column comment coverage** — the fraction of columns on base tables that have a non-empty comment set via `COMMENT ON COLUMN`. Comments are stored in `pg_description` and retrieved with `col_description()`.

The Snowflake "semantic view coverage" variant is **not applicable** to PostgreSQL. PostgreSQL has no native semantic view or structured metadata layer equivalent. If structured semantic metadata is needed, consider external catalog tools (e.g., DataHub, OpenMetadata, Amundsen).

A schema can score 1.0 on comment coverage and still lack machine-readable semantics — comments are free-form text, not structured metadata.

## SQL

```sql
WITH column_stats AS (
    SELECT
        COUNT(*) AS total_columns,
        COUNT(*) FILTER (
            WHERE col_description(a.attrelid, a.attnum) IS NOT NULL
              AND col_description(a.attrelid, a.attnum) != ''
        ) AS commented_columns
    FROM pg_attribute a
    JOIN pg_class c ON c.oid = a.attrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
      AND c.relkind = 'r'
      AND a.attnum > 0
      AND NOT a.attisdropped
)
SELECT
    commented_columns,
    total_columns,
    commented_columns::NUMERIC / NULLIF(total_columns::NUMERIC, 0) AS value
FROM column_stats
```
