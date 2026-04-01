# Fix: temporal_scope_declaration

Remediation guidance for undocumented temporal columns.

## Context

Temporal columns without comments lack declared scope — consumers and AI workloads cannot determine whether a column represents a creation timestamp, validity window boundary, effective date, or event time without inspecting data or asking the owner.

Add a `COMMENT` to each temporal column describing its role. Use the `suggested_temporal_role` from the diagnostic query as a starting point.

## Fix: Add comment to temporal column

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ table }} ALTER COLUMN {{ column }} SET COMMENT '{{ comment }}';
```
