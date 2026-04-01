# Fix: schema_evolution_tracking

Remediation guidance for tables without Time Travel retention for schema evolution tracking.

## Context

Snowflake Time Travel is controlled by the `DATA_RETENTION_TIME_IN_DAYS` parameter at the table, schema, or database level. Tables with `retention_time = 0` have no historical schema tracking. Setting retention to 1 or more days enables querying the table at previous points in time, including its schema state.

Enterprise Edition accounts support up to 90 days of retention; Standard Edition supports up to 1 day.

## Fix: Enable Time Travel on a table

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ table }} SET DATA_RETENTION_TIME_IN_DAYS = 1;
```

## Fix: Enable Time Travel at schema level

```sql
ALTER SCHEMA {{ database }}.{{ schema }} SET DATA_RETENTION_TIME_IN_DAYS = 1;
```
