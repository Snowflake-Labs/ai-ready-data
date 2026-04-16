# Fix: schema_type_coverage

Remediation guidance for columns without semantic type coverage.

## Context

There is no automatic fix for missing semantic types. Improving coverage requires adding column comments that describe the semantic role of each column. Use the diagnostic query to identify `UNKNOWN` / `UNDOCUMENTED` columns, then add comments using `COMMENT ON COLUMN`.

In PostgreSQL, `COMMENT ON COLUMN` is idempotent — it overwrites any existing comment. No guard query is needed.

## SQL

### Add semantic type comment to a column

```sql
COMMENT ON COLUMN {{ schema }}.{{ asset }}.{{ column }} IS '{{ comment }}';
```
