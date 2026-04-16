# Check: data_provenance

Fraction of datasets with documented source provenance including origin system, collection method, and upstream lineage.

## Context

Scoped to base tables (ordinary relations, `relkind = 'r'`) in `{{ schema }}`. A table counts as having provenance if its comment (via `obj_description()`) is non-null, longer than 20 characters, and contains at least one provenance keyword (`source`, `origin`, `from`, `upstream`, `loaded`, `extracted`). The 20-character minimum filters out short, non-informative comments.

PostgreSQL stores table comments in `pg_description`, accessed via `obj_description(oid)` on `pg_class`. This is the direct equivalent of Snowflake's `information_schema.tables.comment`.

Returns a float 0–1 representing the fraction of in-scope tables that pass the provenance heuristic.

## SQL

```sql
WITH tables_in_scope AS (
    SELECT
        c.oid,
        c.relname AS table_name,
        obj_description(c.oid) AS comment
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
      AND c.relkind = 'r'
),
tables_with_provenance AS (
    SELECT *
    FROM tables_in_scope
    WHERE comment IS NOT NULL
      AND LENGTH(comment) > 20
      AND (
          LOWER(comment) LIKE '%source%'
          OR LOWER(comment) LIKE '%origin%'
          OR LOWER(comment) LIKE '%from%'
          OR LOWER(comment) LIKE '%upstream%'
          OR LOWER(comment) LIKE '%loaded%'
          OR LOWER(comment) LIKE '%extracted%'
      )
)
SELECT
    (SELECT COUNT(*) FROM tables_with_provenance) AS tables_with_provenance,
    (SELECT COUNT(*) FROM tables_in_scope) AS total_tables,
    (SELECT COUNT(*) FROM tables_with_provenance)::NUMERIC /
        NULLIF((SELECT COUNT(*) FROM tables_in_scope)::NUMERIC, 0) AS value
```
