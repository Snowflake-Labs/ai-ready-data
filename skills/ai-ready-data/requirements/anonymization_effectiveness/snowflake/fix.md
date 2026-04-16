# Fix: anonymization_effectiveness

Apply masking policies to unprotected PII columns.

## Context

This requirement delegates to the `sensitive-data-classification` skill for thorough PII detection, and to the `data-policy` skill or `column_masking` requirement for masking policy creation and application.

The heuristic PII detection in the check is a starting point — it catches obvious column names but misses PII in generically named columns. Before creating masking policies, consider running `SYSTEM$CLASSIFY` via the `sensitive-data-classification` skill for a comprehensive PII inventory.

Masking policies in Snowflake should use `IS_ROLE_IN_SESSION()`, not `CURRENT_ROLE()` — the latter does not respect role hierarchy. See the `column_masking` requirement for full masking policy creation and application.

## Fix: Run sensitive data classification first

Use Snowflake's built-in classification to identify PII beyond what name-pattern heuristics catch. `SYSTEM$CLASSIFY` is a scalar SQL function that returns a semi-structured classification report for the target table:

```sql
SELECT SYSTEM$CLASSIFY(
    '{{ database }}.{{ schema }}.{{ asset }}',
    {'auto_tag': false}
) AS classification;
```

To persist the output for downstream review, wrap the call in an INSERT into a governance log table, or use the Classification Profile flow documented by the `sensitive-data-classification` skill.

## Fix: Apply masking policies

After identifying PII columns, create and apply masking policies. See the `column_masking` requirement's fix for the full workflow including policy creation, role-based access, and idempotency guards.
