# Check: impact_analysis_capability

Fraction of datasets for which downstream impact of a schema or content change can be automatically enumerated.

## Context

Uses `pg_depend` to count how many base tables in the schema have at least one downstream dependent (view, materialized view, or function). The ratio of tables-with-dependents to total tables is the score.

A score of 1.0 means every base table has at least one tracked downstream dependent, enabling impact analysis before schema changes — e.g., knowing which views will break if a column is dropped.

PostgreSQL's `pg_depend` captures static DDL-level dependencies. Tables consumed only by application queries or external tools will show as having no downstream impact chain.

## SQL

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
      AND c.relkind = 'r'
),
tables_with_downstream AS (
    SELECT COUNT(DISTINCT src.relname) AS cnt
    FROM pg_class src
    JOIN pg_namespace n ON n.oid = src.relnamespace
    JOIN pg_depend d ON d.refobjid = src.oid
    JOIN pg_class dc ON dc.oid = d.objid
    WHERE n.nspname = '{{ schema }}'
      AND src.relkind = 'r'
      AND dc.relkind IN ('v', 'm')
      AND d.deptype = 'n'
      AND d.objid <> d.refobjid
)
SELECT
    tables_with_downstream.cnt AS tables_with_dependents,
    table_count.cnt AS total_tables,
    tables_with_downstream.cnt::NUMERIC / NULLIF(table_count.cnt::NUMERIC, 0) AS value
FROM table_count, tables_with_downstream;
```
