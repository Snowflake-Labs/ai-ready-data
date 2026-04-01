# Fix: column_masking

Create masking policies and apply them to PII columns.

## Context

Two-step process: create the masking policy, then apply it to the column. Delegates to the `data-policy` skill for comprehensive policy management.

**Critical:** Always use `IS_ROLE_IN_SESSION()` in masking policies, never `CURRENT_ROLE()`. `CURRENT_ROLE()` does not respect Snowflake's role hierarchy, so users who inherit a privileged role through the hierarchy will still see masked data.

Before creating a policy, check if it already exists:

```sql
SHOW MASKING POLICIES LIKE '{{ policy_name }}' IN SCHEMA {{ database }}.{{ schema }};
```

If rows are returned, skip policy creation.

`account_usage.policy_references` has approximately 2-hour latency — re-running the check immediately after applying a policy may not reflect the change.

## Fix: Create a masking policy

```sql
CREATE MASKING POLICY IF NOT EXISTS {{ database }}.{{ schema }}.{{ policy_name }}
AS (val {{ data_type }}) RETURNS {{ data_type }} ->
CASE
    WHEN IS_ROLE_IN_SESSION('{{ privileged_role }}') THEN val
    ELSE {{ redacted_value }}
END
```

## Fix: Apply masking policy to a column

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ asset }}
MODIFY COLUMN {{ column }}
SET MASKING POLICY {{ policy_name }}
```
