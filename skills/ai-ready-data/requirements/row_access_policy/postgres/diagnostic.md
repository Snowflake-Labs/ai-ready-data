# Diagnostic: row_access_policy

Per-table breakdown of RLS status and policy assignments.

## Context

Lists every base table in the schema with its RLS enabled flag and any associated policies from `pg_policy`. Tables with status `NO_RLS` need `ALTER TABLE ... ENABLE ROW LEVEL SECURITY` and at least one `CREATE POLICY`.

Tables with `RLS_ENABLED` but no policies will deny all access to non-owner roles — the diagnostic flags these as `RLS_NO_POLICIES` so they can be addressed.

## SQL

```sql
SELECT
    c.relname                          AS table_name,
    c.relrowsecurity                   AS rls_enabled,
    p.polname                          AS policy_name,
    CASE p.polcmd
        WHEN 'r' THEN 'SELECT'
        WHEN 'a' THEN 'INSERT'
        WHEN 'w' THEN 'UPDATE'
        WHEN 'd' THEN 'DELETE'
        WHEN '*' THEN 'ALL'
        ELSE p.polcmd::TEXT
    END                                AS policy_command,
    CASE
        WHEN NOT c.relrowsecurity           THEN 'NO_RLS'
        WHEN c.relrowsecurity AND p.polname IS NULL THEN 'RLS_NO_POLICIES'
        ELSE 'RLS_WITH_POLICY'
    END                                AS status
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_policy p ON p.polrelid = c.oid
WHERE n.nspname = '{{ schema }}'
  AND c.relkind = 'r'
ORDER BY status, c.relname, p.polname;
```
