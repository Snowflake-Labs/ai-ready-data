# Fix: row_access_policy

Remediation guidance for tables without row access policies.

## Context

Row access policies in Snowflake enforce row-level security by filtering rows returned to a query based on the current role or user. To improve the row_access_policy score, create a policy and attach it to each unprotected table.

1. **Create a row access policy** that defines which roles can see which rows.
2. **Attach the policy** to each table that needs row-level filtering.

## Remediation: Create a row access policy

```sql
CREATE OR REPLACE ROW ACCESS POLICY {{ database }}.{{ schema }}.{{ policy_name }}
AS (val VARCHAR) RETURNS BOOLEAN ->
    CURRENT_ROLE() IN ('{{ allowed_role }}');
```

## Remediation: Attach the policy to a table

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ table_name }}
    ADD ROW ACCESS POLICY {{ database }}.{{ schema }}.{{ policy_name }} ON ({{ column_name }});
```