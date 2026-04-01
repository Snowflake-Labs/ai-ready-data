# Fix: unit_of_measure_declaration

Remediation guidance for numeric columns missing unit-of-measure declarations.

## Context

The primary remediation is to add a comment to each numeric column that documents its unit using `COMMENT ON COLUMN`. This is the lowest-friction approach — it requires no schema changes and is immediately visible to both human analysts and AI agents querying column metadata via `col_description()`.

Alternatively, columns can be renamed to include unit suffixes (e.g., `revenue` -> `revenue_usd`), but this is a breaking change for downstream consumers.

In PostgreSQL, `COMMENT ON COLUMN` is idempotent — it overwrites any existing comment. No guard query is needed.

## SQL

### Add unit-of-measure comment to a column

```sql
COMMENT ON COLUMN {{ schema }}.{{ table }}.{{ column }} IS '{{ comment_with_unit }}';
```
