# Check: data_provenance

Fraction of datasets with documented source provenance including origin system, collection method, and upstream lineage.

## Context

Scoped to base tables in `{{ database }}.{{ schema }}`. A table counts as having provenance if its comment is non-null, longer than 20 characters, and contains at least one provenance keyword (`source`, `origin`, `from`, `upstream`, `loaded`, `extracted`). The 20-character minimum filters out short, non-informative comments.

Returns a float 0–1 representing the fraction of in-scope tables that pass the provenance heuristic.

## SQL

```sql
WITH tables_in_scope AS (
    SELECT
        table_catalog,
        table_schema,
        table_name,
        comment
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
tables_with_provenance AS (
    SELECT *
    FROM tables_in_scope
    WHERE 
        comment IS NOT NULL 
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
    (SELECT COUNT(*) FROM tables_with_provenance)::FLOAT / 
        NULLIF((SELECT COUNT(*) FROM tables_in_scope)::FLOAT, 0) AS value
```
