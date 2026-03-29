# Check: schema_evolution_tracking

Fraction of base tables in the schema with Time Travel retention enabled, allowing historical schema queries.

## Context

Uses `information_schema.tables` to check each base table's `retention_time`. A value greater than 0 means Time Travel is enabled and the table supports historical schema queries via `AT`/`BEFORE` clauses.

A score of 1.0 means every base table in the schema has Time Travel retention enabled. Tables with `retention_time = 0` cannot be queried historically and have no schema version tracking.

## SQL

```sql
WITH tables_in_scope AS (
    SELECT 
        table_catalog,
        table_schema,
        table_name,
        created,
        last_altered,
        retention_time
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
-- Tables with Time Travel retention > 0 (enables historical queries)
tables_with_retention AS (
    SELECT table_name
    FROM tables_in_scope
    WHERE retention_time > 0
)
SELECT
    (SELECT COUNT(*) FROM tables_with_retention) AS tables_with_tracking,
    (SELECT COUNT(*) FROM tables_in_scope) AS total_tables,
    (SELECT COUNT(*) FROM tables_with_retention)::FLOAT / 
        NULLIF((SELECT COUNT(*) FROM tables_in_scope)::FLOAT, 0) AS value
```
