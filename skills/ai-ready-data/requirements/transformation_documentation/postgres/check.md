# Check: transformation_documentation

Fraction of data transformations with documented logic, inputs, and outputs.

## Context

In PostgreSQL, transformation objects include:

- **Views** (`relkind = 'v'`) — self-documenting via their stored SQL definition in `pg_views.definition`, but benefit from comments explaining purpose and business logic.
- **Materialized views** (`relkind = 'm'`) — similarly self-documenting via their definition, but should have comments.
- **Functions/procedures** (`pg_proc`) — contain transformation logic in `prosrc`, but should have comments explaining intent.

PostgreSQL does not have Snowflake's "dynamic tables." The closest equivalents are materialized views (with scheduled refresh) or functions.

A transformation is considered documented if it has a `COMMENT` that is non-null and longer than 20 characters. Views and materialized views get partial credit for having a stored definition, but a comment is still required for the check to pass — the definition alone doesn't explain business intent.

## SQL

```sql
WITH transformations AS (
    SELECT c.oid, c.relname AS object_name, 'VIEW' AS object_type
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
      AND c.relkind IN ('v', 'm')

    UNION ALL

    SELECT p.oid, p.proname AS object_name, 'FUNCTION' AS object_type
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = '{{ schema }}'
      AND p.prokind IN ('f', 'p')
),
documented AS (
    SELECT * FROM transformations
    WHERE obj_description(oid) IS NOT NULL
      AND LENGTH(obj_description(oid)) > 20
)
SELECT
    (SELECT COUNT(*) FROM documented) AS documented_count,
    (SELECT COUNT(*) FROM transformations) AS total_count,
    (SELECT COUNT(*) FROM documented)::NUMERIC /
        NULLIF((SELECT COUNT(*) FROM transformations)::NUMERIC, 0) AS value
```
