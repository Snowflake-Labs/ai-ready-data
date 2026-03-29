# Fix: feature_refresh_compliance

## Context

Manually triggers a refresh of a dynamic table that has fallen behind its target lag or is in a non-compliant state.

## SQL

### refresh-dynamic-table

```sql
ALTER DYNAMIC TABLE {{ database }}.{{ schema }}.{{ asset }} REFRESH
```
