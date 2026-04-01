# Diagnostic: data_version_coverage

Per-table breakdown of versioning pattern presence across the schema.

## Context

Lists every base table and checks whether it contains recognized versioning signals:

- **Temporal columns** — `valid_from`, `valid_to`, `effective_from`, `effective_to`, `version`, `sys_period`, or columns matching `*_version*`.
- **Audit triggers** — triggers named `%audit%`, `%history%`, or `%version%`.
- **Explicit version columns** — `version`, `version_id`, `data_version`, `snapshot_id`, `batch_id`.

Tables are classified as `HAS_VERSIONING` or `NO_VERSIONING`. Includes table size to help prioritize remediation.

This is complementary to the check query: both use heuristics since PostgreSQL has no native Time Travel. A table may have versioning mechanisms not detected by these patterns (e.g., application-level versioning stored in a separate table).

## SQL

```sql
WITH all_tables AS (
    SELECT c.oid, c.relname AS table_name
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
        AND c.relkind = 'r'
),
temporal_cols AS (
    SELECT
        c.relname AS table_name,
        STRING_AGG(a.attname, ', ' ORDER BY a.attname) AS temporal_columns
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
                'version', 'version_id', 'data_version',
                'snapshot_id', 'batch_id', 'sys_period'
            )
            OR LOWER(a.attname) LIKE '%\_version%'
        )
    GROUP BY c.relname
),
audit_trigs AS (
    SELECT
        c.relname AS table_name,
        STRING_AGG(t.tgname, ', ' ORDER BY t.tgname) AS audit_triggers
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
    GROUP BY c.relname
)
SELECT
    t.table_name,
    pg_relation_size(t.oid) / (1024 * 1024) AS size_mb,
    COALESCE(tc.temporal_columns, 'none') AS temporal_columns,
    COALESCE(at.audit_triggers, 'none') AS audit_triggers,
    CASE
        WHEN tc.table_name IS NOT NULL OR at.table_name IS NOT NULL THEN 'HAS_VERSIONING'
        ELSE 'NO_VERSIONING'
    END AS version_status
FROM all_tables t
LEFT JOIN temporal_cols tc ON t.table_name = tc.table_name
LEFT JOIN audit_trigs at ON t.table_name = at.table_name
ORDER BY version_status DESC, t.table_name
```
