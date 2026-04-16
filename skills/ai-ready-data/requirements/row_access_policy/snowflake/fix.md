# Fix: row_access_policy

Remediation guidance for tables without row access policies.

## Context

Row access policies in Snowflake enforce row-level security by filtering rows returned to a query based on the caller's active role hierarchy. To improve the row_access_policy score, create a policy and attach it to each unprotected table.

1. **Create a row access policy** that defines which roles can see which rows.
2. **Attach the policy** to each table that needs row-level filtering.

**Critical:** Always use `IS_ROLE_IN_SESSION(...)` in row access policies, never `CURRENT_ROLE()`. `CURRENT_ROLE()` does not respect Snowflake's role hierarchy — a user whose active role inherits `{{ allowed_role }}` would be blocked even though they should have access. The same anti-pattern warning applies as for masking policies.

Before creating a policy, check whether it already exists:

```sql
SHOW ROW ACCESS POLICIES LIKE '{{ policy_name }}' IN SCHEMA {{ database }}.{{ schema }};
```

If rows are returned, skip the CREATE and go straight to the ALTER TABLE step.

`account_usage.policy_references` has approximately 2-hour latency — the check may not reflect an attached policy immediately.

## Fix: Create a row access policy

```sql
CREATE ROW ACCESS POLICY IF NOT EXISTS {{ database }}.{{ schema }}.{{ policy_name }}
AS (val VARCHAR) RETURNS BOOLEAN ->
    IS_ROLE_IN_SESSION('{{ allowed_role }}');
```

## Fix: Attach the policy to a table

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ asset }}
    ADD ROW ACCESS POLICY {{ database }}.{{ schema }}.{{ policy_name }} ON ({{ column }});
```