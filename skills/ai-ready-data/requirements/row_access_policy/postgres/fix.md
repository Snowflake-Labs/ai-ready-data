# Fix: row_access_policy

Enable row-level security and create policies on unprotected tables.

## Context

PostgreSQL RLS is a two-step process: enable RLS on the table, then create one or more policies that define which rows are visible to which roles. Without at least one policy, RLS defaults to deny-all for non-owner roles.

The table owner bypasses RLS by default. To force the owner to also go through policies, use `ALTER TABLE ... FORCE ROW LEVEL SECURITY`.

Before enabling RLS, verify it is not already enabled:

```sql
SELECT relrowsecurity
FROM pg_class
WHERE oid = '{{ schema }}.{{ asset }}'::regclass;
```

If `true`, skip the enable step. Before creating a policy, check if it already exists:

```sql
SELECT 1 FROM pg_policy WHERE polname = '{{ policy_name }}';
```

## Remediation: Enable RLS on a table

```sql
ALTER TABLE {{ schema }}.{{ asset }} ENABLE ROW LEVEL SECURITY;
```

## Remediation: Create a row-level security policy

```sql
CREATE POLICY {{ policy_name }} ON {{ schema }}.{{ asset }}
    FOR SELECT
    USING ({{ filter_expression }});
```

Replace `{{ filter_expression }}` with the appropriate predicate, e.g.:

- `tenant_id = current_setting('app.tenant_id')::INT` for tenant isolation
- `owner_role = current_user` for owner-based access
- `sensitivity_level <= current_setting('app.clearance')::INT` for classification-based filtering

## Remediation: Force owner through RLS (optional)

```sql
ALTER TABLE {{ schema }}.{{ asset }} FORCE ROW LEVEL SECURITY;
```
