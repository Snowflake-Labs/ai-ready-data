# Fix: temporal_scope_declaration

Remediation guidance for undocumented temporal columns.

## Context

Temporal columns without comments lack declared scope — consumers and AI workloads cannot determine whether a column represents a creation timestamp, validity window boundary, effective date, or event time without inspecting data or asking the owner.

Add a comment to each temporal column describing its role using `COMMENT ON COLUMN`. Use the `suggested_temporal_role` from the diagnostic query as a starting point.

In PostgreSQL, `COMMENT ON COLUMN` is idempotent — it overwrites any existing comment. No guard query is needed.

## SQL

### Add comment to temporal column

```sql
COMMENT ON COLUMN {{ schema }}.{{ table }}.{{ column }} IS '{{ comment }}';
```
