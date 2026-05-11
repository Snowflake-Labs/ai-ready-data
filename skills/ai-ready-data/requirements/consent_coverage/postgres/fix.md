# Fix: consent_coverage

Add consent/legal-basis documentation to table comments.

## Context

This is a governance process — the comment should only be applied after the organisation has determined and documented the legal basis for AI processing of the data in each table. Applying a comment without a real legal basis determination creates a false compliance signal.

PostgreSQL uses `COMMENT ON TABLE` to attach metadata to tables. Unlike Snowflake's tag system with allowed values and structured lookups, PostgreSQL comments are free-text. Adopt a consistent format (e.g., `legal_basis: consent`) so the check query can detect them reliably.

Common legal basis values (GDPR Article 6): `consent`, `legitimate_interest`, `contract`, `legal_obligation`, `public_interest`, `vital_interest`.

## Remediation: Add consent documentation to a table comment

```sql
COMMENT ON TABLE {{ schema }}.{{ asset }} IS 'legal_basis: {{ legal_basis_value }}; purpose: {{ purpose_description }}';
```

## Remediation: Append to an existing table comment

If the table already has a comment, append the consent documentation:

```sql
COMMENT ON TABLE {{ schema }}.{{ asset }} IS (
    SELECT COALESCE(obj_description(c.oid), '') || '; legal_basis: {{ legal_basis_value }}'
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}' AND c.relname = '{{ asset }}'
);
```
