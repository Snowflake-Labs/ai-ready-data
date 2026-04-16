# Fix: feature_materialization_coverage

Remediation guidance for creating materialized views to improve feature materialization coverage.

## Context

Materialization strategy depends on query patterns, refresh cadence, and storage constraints. PostgreSQL materialized views store a snapshot of a query result and must be explicitly refreshed. Unlike Snowflake dynamic tables, they do not auto-refresh based on a target lag.

## Remediation: Create a materialized view

Create a materialized view for a base table that needs pre-computation:

```sql
CREATE MATERIALIZED VIEW {{ schema }}.{{ asset }}_mv AS
    SELECT * FROM {{ source_query }}
WITH DATA;
```

Add a unique index to support `REFRESH MATERIALIZED VIEW CONCURRENTLY`:

```sql
CREATE UNIQUE INDEX ON {{ schema }}.{{ asset }}_mv ({{ primary_key }});
```

## Remediation: Schedule periodic refresh

Use `pg_cron` to automate materialized view refresh:

```sql
SELECT cron.schedule(
    '{{ asset }}_mv_refresh',
    '0 * * * *',
    $$REFRESH MATERIALIZED VIEW CONCURRENTLY {{ schema }}.{{ asset }}_mv$$
);
```

## Remediation: Manual refresh

For ad-hoc refresh or environments without `pg_cron`:

```sql
REFRESH MATERIALIZED VIEW {{ schema }}.{{ asset }}_mv;
```

Use `CONCURRENTLY` to allow reads during refresh (requires a unique index):

```sql
REFRESH MATERIALIZED VIEW CONCURRENTLY {{ schema }}.{{ asset }}_mv;
```
