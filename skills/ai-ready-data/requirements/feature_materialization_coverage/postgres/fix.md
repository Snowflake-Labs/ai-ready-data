# Fix: feature_materialization_coverage

Remediation guidance for creating materialized views to pre-compute features.

## Context

Materialization strategy depends on query patterns, refresh cadence, and storage constraints. PostgreSQL materialized views are full snapshots — each `REFRESH` rewrites the entire view. For large datasets, `REFRESH MATERIALIZED VIEW CONCURRENTLY` allows reads during refresh but requires a unique index.

There is no automated one-size-fits-all fix. The guidance below provides templates for common materialization patterns.

## Remediation: Create a materialized view

Create a materialized view from the source table's transformation logic:

```sql
CREATE MATERIALIZED VIEW {{ schema }}.{{ asset }}_mv AS
    {{ source_query }};
```

## Remediation: Add a unique index for concurrent refresh

A unique index is required to use `REFRESH MATERIALIZED VIEW CONCURRENTLY`:

```sql
CREATE UNIQUE INDEX {{ asset }}_mv_unique_idx
    ON {{ schema }}.{{ asset }}_mv ({{ unique_key }});
```

## Remediation: Schedule periodic refresh with pg_cron

Use `pg_cron` to refresh the materialized view on a schedule:

```sql
SELECT cron.schedule(
    'refresh_{{ asset }}_mv',
    '0 */1 * * *',
    'REFRESH MATERIALIZED VIEW CONCURRENTLY {{ schema }}.{{ asset }}_mv'
);
```

## Remediation: Manual refresh

For ad-hoc or pipeline-triggered refreshes:

```sql
REFRESH MATERIALIZED VIEW {{ schema }}.{{ asset }}_mv;
```
