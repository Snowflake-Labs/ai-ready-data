# Fix: data_freshness

Force-refresh a dynamic table to bring it within its freshness SLA.

## Context

Triggers an immediate refresh of the specified dynamic table. This is only applicable to dynamic tables — for standard tables, freshness depends on upstream pipelines delivering new data. After refreshing, `DATA_TIMESTAMP` on the dynamic table will update to reflect the latest materialized state.

`last_altered` reflects DDL changes, not DML, so refreshing a dynamic table will not necessarily update `last_altered`. Use `DATA_TIMESTAMP` or streams for accurate freshness tracking on dynamic tables.

## SQL

```sql
ALTER DYNAMIC TABLE {{ database }}.{{ schema }}.{{ asset }} REFRESH
```