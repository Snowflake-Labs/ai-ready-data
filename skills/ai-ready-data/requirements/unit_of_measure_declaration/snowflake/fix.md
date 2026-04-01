# Fix: unit_of_measure_declaration

Remediation guidance for numeric columns missing unit-of-measure declarations.

## Context

The primary remediation is to add a `COMMENT` to each numeric column that documents its unit. This is the lowest-friction approach — it requires no schema changes and is immediately visible to both human analysts and AI agents querying `information_schema.columns`.

Alternatively, columns can be renamed to include unit suffixes (e.g., `revenue` → `revenue_usd`), but this is a breaking change for downstream consumers.

## Fix: Add unit-of-measure comment to a column

```sql
COMMENT ON COLUMN {{ database }}.{{ schema }}.{{ table }}.{{ column }} IS '{{ comment_with_unit }}';
```