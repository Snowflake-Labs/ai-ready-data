# Check: data_version_coverage

Fraction of datasets with point-in-time state reconstruction capability.

## Context

PostgreSQL has no native Time Travel equivalent. This check uses heuristics to detect versioning patterns:

- **Temporal columns** — columns named `valid_from`, `valid_to`, `effective_from`, `effective_to`, `version`, `sys_period`, or `*_version*` suggest SCD Type 2 or temporal table patterns.
- **Audit triggers** — triggers named `%audit%`, `%history%`, or `%version%` suggest trigger-based change history capture.

A table matching either pattern is considered to have versioning capability. The score is the fraction of base tables with at least one versioning signal.

This is a heuristic check — false positives are possible if column names or trigger names happen to match the patterns without actually implementing versioning.

## SQL

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'r'
),
temporal_tables AS (
    SELECT DISTINCT c.relname
    FROM pg_attribute a
    JOIN pg_class c ON c.oid = a.attrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'r'
        AND a.attnum > 0
        AND NOT a.attisdropped
        AND (
            LOWER(a.attname) IN (
                'valid_from', 'valid_to',
                'effective_from', 'effective_to',
                'version', 'sys_period'
            )
            OR LOWER(a.attname) LIKE '%\_version%'
        )
),
audit_tables AS (
    SELECT DISTINCT c.relname
    FROM pg_trigger t
    JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'r'
        AND (
            LOWER(t.tgname) LIKE '%audit%'
            OR LOWER(t.tgname) LIKE '%history%'
            OR LOWER(t.tgname) LIKE '%version%'
        )
),
versioned_tables AS (
    SELECT relname FROM temporal_tables
    UNION
    SELECT relname FROM audit_tables
)
SELECT
    (SELECT COUNT(*) FROM versioned_tables) AS tables_with_versioning,
    table_count.cnt AS total_tables,
    (SELECT COUNT(*) FROM versioned_tables)::NUMERIC
        / NULLIF(table_count.cnt::NUMERIC, 0) AS value
FROM table_count
```
