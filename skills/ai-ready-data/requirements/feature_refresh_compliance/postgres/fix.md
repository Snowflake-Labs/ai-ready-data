# Fix: feature_refresh_compliance

Remediation guidance for stale materialized views and tables.

## Context

PostgreSQL materialized views require explicit refresh — they do not auto-update like Snowflake dynamic tables. Staleness is the default state unless refresh schedules are configured. The primary remediation is to establish automated refresh schedules using `pg_cron` or an external scheduler.

## Remediation: Refresh a materialized view

Manually trigger a refresh for a stale materialized view:

```sql
REFRESH MATERIALIZED VIEW {{ schema }}.{{ asset }};
```

Use `CONCURRENTLY` to allow reads during refresh (requires a unique index on the view):

```sql
REFRESH MATERIALIZED VIEW CONCURRENTLY {{ schema }}.{{ asset }};
```

## Remediation: Schedule automated refresh with pg_cron

Install `pg_cron` and schedule periodic refreshes to prevent staleness:

```sql
SELECT cron.schedule(
    '{{ asset }}_refresh',
    '0 * * * *',
    $$REFRESH MATERIALIZED VIEW CONCURRENTLY {{ schema }}.{{ asset }}$$
);
```

Adjust the cron expression to match your staleness tolerance (e.g., `'*/15 * * * *'` for every 15 minutes).

## Remediation: Run ANALYZE on stale tables

For base tables showing as stale, run ANALYZE to update statistics and confirm activity:

```sql
ANALYZE {{ schema }}.{{ asset }};
```

## Remediation: Configure autovacuum for freshness

Ensure autovacuum runs frequently enough to keep statistics current:

```sql
ALTER TABLE {{ schema }}.{{ asset }} SET (
    autovacuum_analyze_scale_factor = 0.005,
    autovacuum_analyze_threshold = 100
);
```
