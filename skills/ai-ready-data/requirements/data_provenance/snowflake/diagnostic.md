# Diagnostic: data_provenance

Shows tables and their provenance documentation status.

## Context

Lists every base table in `{{ database }}.{{ schema }}` with its row count, creation date, and a provenance status classification: `DOCUMENTED` (comment exists and is longer than 20 characters), `PARTIAL` (comment exists but is short), or `UNDOCUMENTED` (no comment at all).

The recommendation column checks for the keywords `source` or `origin` in the comment to confirm provenance is present, and otherwise advises adding a `COMMENT` that includes the source system, collection method, and upstream lineage.

Results are ordered with undocumented tables first to surface the highest-priority gaps.

## SQL

```sql
SELECT
    t.table_catalog AS database_name,
    t.table_schema AS schema_name,
    t.table_name,
    t.row_count,
    t.created AS table_created,
    CASE
        WHEN t.comment IS NOT NULL AND LENGTH(t.comment) > 20 THEN 'DOCUMENTED'
        WHEN t.comment IS NOT NULL THEN 'PARTIAL'
        ELSE 'UNDOCUMENTED'
    END AS provenance_status,
    COALESCE(t.comment, '') AS current_comment,
    CASE
        WHEN t.comment IS NOT NULL AND (
            LOWER(t.comment) LIKE '%source%'
            OR LOWER(t.comment) LIKE '%origin%'
        ) THEN 'Provenance documented in comment'
        ELSE 'Add COMMENT with source system, collection method, and upstream lineage'
    END AS recommendation
FROM {{ database }}.information_schema.tables t
WHERE t.table_schema = '{{ schema }}'
    AND t.table_type = 'BASE TABLE'
ORDER BY provenance_status DESC, t.table_name
```
