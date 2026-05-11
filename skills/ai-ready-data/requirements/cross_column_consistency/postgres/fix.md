# Fix: cross_column_consistency

Guidance for remediating cross-column consistency violations.

## Context

There is no generic fix SQL for cross-column consistency because the correct remediation depends entirely on the business rule being violated and which column holds the correct value. Automated fixes risk data loss if applied without domain understanding.

### Remediation approaches

- **Null out the suspect column** — When one column is clearly authoritative (e.g., `start_date` is trusted, `end_date` is not), set the unreliable column to NULL for violated rows so downstream consumers don't ingest contradictory data.
- **Recompute derived columns** — When one column is a function of others (e.g., `total = quantity * unit_price`), UPDATE the derived column using the formula.
- **Flag for manual review** — Add a `needs_review` boolean column and set it to TRUE for violated rows, then route them to a data steward.
- **Apply DEFAULT or business-rule fallback** — For status/date mismatches (e.g., `status = 'SHIPPED'` but `shipped_date IS NULL`), apply a default value like `CURRENT_TIMESTAMP` if business policy allows.
- **Add CHECK constraint** — PostgreSQL supports multi-column CHECK constraints that enforce cross-column rules at the schema level. After fixing existing violations, add a constraint to prevent future ones:

```sql
ALTER TABLE {{ schema }}.{{ asset }}
ADD CONSTRAINT {{ asset }}_consistency_check
CHECK ({{ consistency_rule }})
```

In all cases, run the diagnostic query first to understand the scope and pattern of violations before writing a targeted UPDATE statement.
