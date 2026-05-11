# Fix: purpose_limitation

Add purpose declarations to tables without declared AI processing purposes.

## Context

PostgreSQL has no native tagging system. Purpose declarations can be implemented via:

1. **Security labels** — the closest analog to Snowflake tags. Requires a label provider (e.g., `postgresql_anonymizer` or a custom provider). Labels are stored in `pg_seclabel` and are queryable.
2. **Table comments** — structured comments can encode purpose metadata. Less formal than security labels but universally available without extensions.
3. **Purpose-named RLS policies** — encode purpose in the policy name, combining access control with purpose documentation.

Security labels are preferred when a label provider is available, as they provide a dedicated metadata channel separate from documentation comments.

## Remediation: Apply a security label

Requires a label provider to be configured. Example with a custom provider:

```sql
SECURITY LABEL FOR {{ provider }} ON TABLE {{ schema }}.{{ asset }}
    IS '{{ purpose_value }}';
```

Example values: `purpose:training`, `purpose:serving`, `purpose:rag`, `purpose:analytics`.

## Remediation: Use structured table comments

If no label provider is available, use a structured comment convention:

```sql
COMMENT ON TABLE {{ schema }}.{{ asset }}
    IS 'purpose={{ purpose_value }}; {{ existing_comment }}';
```

## Remediation: Create a purpose-named RLS policy

Combines purpose declaration with access enforcement:

```sql
ALTER TABLE {{ schema }}.{{ asset }} ENABLE ROW LEVEL SECURITY;

CREATE POLICY purpose_{{ purpose_value }} ON {{ schema }}.{{ asset }}
    FOR SELECT
    USING (true);
```

This creates a permissive policy whose name encodes the allowed purpose. Tighten the `USING` clause to restrict access by role or session variable as needed.
