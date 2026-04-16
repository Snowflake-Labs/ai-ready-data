# Fix: anonymization_effectiveness

Apply access restrictions to unprotected PII columns.

## Context

This requirement uses a broader PII pattern set than `column_masking`. Before applying restrictions, consider running a more thorough PII scan — PostgreSQL has no built-in classification like Snowflake's `SYSTEM$CLASSIFY`, but the `postgresql_anonymizer` extension can detect PII patterns, or you can use application-level scanning tools.

PostgreSQL has no native masking policies. The primary remediation approaches are:

1. **Column-level REVOKE/GRANT** — strongest built-in mechanism
2. **Security labels** — via `postgresql_anonymizer` for declarative masking
3. **Masking views** — for role-based redaction

See the `column_masking` requirement's fix for the full column-level restriction and masking view workflow.

## Remediation: Restrict column-level access

```sql
REVOKE SELECT ({{ column }}) ON {{ schema }}.{{ asset }} FROM PUBLIC;
GRANT SELECT ({{ column }}) ON {{ schema }}.{{ asset }} TO {{ privileged_role }};
```

## Remediation: Apply security labels with postgresql_anonymizer

If the `postgresql_anonymizer` extension is available, use declarative masking:

```sql
CREATE EXTENSION IF NOT EXISTS anon CASCADE;
SELECT anon.init();

SECURITY LABEL FOR anon ON COLUMN {{ schema }}.{{ asset }}.{{ column }}
    IS 'MASKED WITH FUNCTION {{ masking_function }}';
```

Common masking functions:

- `anon.partial_email({{ column }})` — masks email addresses
- `anon.random_phone()` — replaces phone numbers
- `anon.hash({{ column }})` — one-way hash for pseudonymization
- `anon.fake_last_name()` — synthetic replacement for names

## Remediation: Create masking views

For environments without `postgresql_anonymizer`, create views that redact PII:

```sql
CREATE OR REPLACE VIEW {{ schema }}.{{ asset }}_anonymized AS
SELECT
    {{ non_sensitive_columns }},
    CASE
        WHEN current_user = '{{ privileged_role }}'
        THEN {{ column }}
        ELSE '***REDACTED***'
    END AS {{ column }}
FROM {{ schema }}.{{ asset }};
```
