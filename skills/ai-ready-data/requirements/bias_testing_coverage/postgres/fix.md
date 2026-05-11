# Fix: bias_testing_coverage

Add bias testing documentation to table comments.

## Context

This is a two-step process: first perform the actual bias testing externally, then document the result in the table comment. The comment is a governance signal — apply it only after actual bias testing has been performed.

PostgreSQL uses `COMMENT ON TABLE` for table-level metadata. Adopt a consistent format (e.g., `bias_tested: true; bias_test_date: 2024-01-15`) so the check query can detect it reliably.

## Remediation: Document bias testing on a table

```sql
COMMENT ON TABLE {{ schema }}.{{ asset }} IS 'bias_tested: true; bias_test_date: {{ test_date }}; bias_status: {{ status }}';
```

## Remediation: Append bias testing documentation to an existing comment

If the table already has a comment, append the bias testing documentation:

```sql
COMMENT ON TABLE {{ schema }}.{{ asset }} IS (
    SELECT COALESCE(obj_description(c.oid), '') || '; bias_tested: true; bias_test_date: {{ test_date }}'
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = '{{ schema }}' AND c.relname = '{{ asset }}'
);
```
