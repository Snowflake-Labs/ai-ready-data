# Check: row_access_policy

Fraction of tables with row-level security enabled.

## Context

Uses `pg_class.relrowsecurity` to identify tables with RLS enabled and `pg_policy` to verify policies exist. PostgreSQL has native RLS — unlike Snowflake's policy-reference model, RLS is a per-table boolean flag plus one or more `CREATE POLICY` definitions.

A table with `relrowsecurity = true` but no policies will deny all access to non-owner roles (implicit deny). This check counts tables where RLS is enabled regardless of whether policies are defined — the diagnostic reveals the policy details.

A score of 1.0 means every base table in the schema has RLS enabled.

## SQL

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
      AND c.relkind = 'r'
),
rls_tables AS (
    SELECT COUNT(*) AS cnt
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}'
      AND c.relkind = 'r'
      AND c.relrowsecurity = true
)
SELECT
    rls_tables.cnt   AS tables_with_rls,
    table_count.cnt  AS total_tables,
    rls_tables.cnt::NUMERIC / NULLIF(table_count.cnt::NUMERIC, 0) AS value
FROM table_count, rls_tables;
```
