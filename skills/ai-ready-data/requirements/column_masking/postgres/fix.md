# Fix: column_masking

Restrict access to PII columns via column-level privileges or masking views.

## Context

PostgreSQL has no native masking policies like Snowflake. Two primary approaches exist:

1. **Column-level REVOKE/GRANT** — revoke SELECT on specific columns from PUBLIC, then grant to authorized roles only. Simple but coarse: the column is either fully visible or fully hidden.
2. **Masking views** — create a view that replaces sensitive values with redacted output for non-privileged roles, then grant access to the view instead of the base table.

For declarative masking similar to Snowflake, consider the `postgresql_anonymizer` extension which supports masking rules on columns.

## Remediation: Revoke column-level SELECT from PUBLIC

```sql
REVOKE SELECT ({{ column }}) ON {{ schema }}.{{ asset }} FROM PUBLIC;
```

Then grant to authorized roles:

```sql
GRANT SELECT ({{ column }}) ON {{ schema }}.{{ asset }} TO {{ privileged_role }};
```

## Remediation: Create a masking view

```sql
CREATE OR REPLACE VIEW {{ schema }}.{{ asset }}_masked AS
SELECT
    {{ non_sensitive_columns }},
    CASE
        WHEN current_user = '{{ privileged_role }}'
        THEN {{ column }}
        ELSE '***MASKED***'
    END AS {{ column }}
FROM {{ schema }}.{{ asset }};
```

Grant access to the view and revoke direct table access for non-privileged roles:

```sql
REVOKE SELECT ON {{ schema }}.{{ asset }} FROM {{ restricted_role }};
GRANT SELECT ON {{ schema }}.{{ asset }}_masked TO {{ restricted_role }};
```

## Remediation: Use postgresql_anonymizer (optional)

If the `postgresql_anonymizer` extension is available:

```sql
CREATE EXTENSION IF NOT EXISTS anon CASCADE;
SELECT anon.init();

SECURITY LABEL FOR anon ON COLUMN {{ schema }}.{{ asset }}.{{ column }}
    IS 'MASKED WITH FUNCTION anon.partial_email({{ column }})';
```
