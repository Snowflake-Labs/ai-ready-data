# Diagnostic: data_provenance

Shows tables and their provenance documentation status.

## Context

Lists every base table in `{{ schema }}` with its estimated row count, creation-time proxy (not natively available in PostgreSQL — uses `NULL` placeholder), and a provenance status classification: `DOCUMENTED` (comment exists and is longer than 20 characters), `PARTIAL` (comment exists but is short), or `UNDOCUMENTED` (no comment at all).

PostgreSQL does not track table creation dates in `pg_class`. The `reltuples` column provides an estimated row count from the last `ANALYZE`.

The recommendation column checks for provenance keywords (`source`, `origin`) in the comment and advises adding a `COMMENT ON TABLE` with source system, collection method, and upstream lineage if absent.

Results are ordered with undocumented tables first to surface the highest-priority gaps.

## SQL

```sql
SELECT
    n.nspname AS schema_name,
    c.relname AS table_name,
    c.reltuples::BIGINT AS estimated_rows,
    CASE
        WHEN obj_description(c.oid) IS NOT NULL AND LENGTH(obj_description(c.oid)) > 20 THEN 'DOCUMENTED'
        WHEN obj_description(c.oid) IS NOT NULL THEN 'PARTIAL'
        ELSE 'UNDOCUMENTED'
    END AS provenance_status,
    COALESCE(obj_description(c.oid), '') AS current_comment,
    CASE
        WHEN obj_description(c.oid) IS NOT NULL AND (
            LOWER(obj_description(c.oid)) LIKE '%source%'
            OR LOWER(obj_description(c.oid)) LIKE '%origin%'
        ) THEN 'Provenance documented in comment'
        ELSE 'Add COMMENT ON TABLE with source system, collection method, and upstream lineage'
    END AS recommendation
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = '{{ schema }}'
  AND c.relkind = 'r'
ORDER BY provenance_status DESC, c.relname
```
