# Fix: license_compliance

Add license documentation to table comments.

## Context

Two remediation steps: first verify the actual license terms for the dataset, then document them in the table comment. The comment is a governance signal — apply it only after verifying the license permits the intended use (e.g., AI training).

PostgreSQL uses `COMMENT ON TABLE` for table-level metadata. Adopt a consistent format (e.g., `license: CC-BY-4.0; usage: training permitted`) so the check query can detect it reliably.

## Remediation: Add license documentation to a table

```sql
COMMENT ON TABLE {{ schema }}.{{ asset }} IS 'license: {{ license_type }}; usage: {{ usage_permissions }}';
```

## Remediation: Append license documentation to an existing comment

If the table already has a comment, append the license documentation:

```sql
COMMENT ON TABLE {{ schema }}.{{ asset }} IS (
    SELECT COALESCE(obj_description(c.oid), '') || '; license: {{ license_type }}; usage: {{ usage_permissions }}'
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}' AND c.relname = '{{ asset }}'
);
```
