# Fix: feature_refresh_compliance

Remediation guidance for stale materialized views.

## Context

Unlike Snowflake dynamic tables which auto-refresh based on `target_lag`, PostgreSQL materialized views require explicit refresh operations. Staleness is entirely the responsibility of the operator — there is no built-in scheduler or lag-based trigger.

## Remediation: Refresh a stale materialized view

Immediately refresh a stale materialized view and update statistics:

```sql
REFRESH MATERIALIZED VIEW {{ schema }}.{{ asset }};
ANALYZE {{ schema }}.{{ asset }};
```

For zero-downtime refreshes (requires a unique index on the view):

```sql
REFRESH MATERIALIZED VIEW CONCURRENTLY {{ schema }}.{{ asset }};
ANALYZE {{ schema }}.{{ asset }};
```

## Remediation: Schedule automated refresh with pg_cron

Install `pg_cron` and create a recurring refresh job:

```sql
CREATE EXTENSION IF NOT EXISTS pg_cron;

SELECT cron.schedule(
    'refresh_{{ asset }}',
    '0 */1 * * *',
    'REFRESH MATERIALIZED VIEW CONCURRENTLY {{ schema }}.{{ asset }}; ANALYZE {{ schema }}.{{ asset }};'
);
```

Adjust the cron expression to match the required staleness tolerance (e.g., `*/15 * * * *` for every 15 minutes).

## Remediation: Add a unique index for concurrent refresh

`CONCURRENTLY` requires a unique index. Create one on the materialized view's primary key or a suitable unique column set:

```sql
CREATE UNIQUE INDEX {{ asset }}_refresh_idx
    ON {{ schema }}.{{ asset }} ({{ unique_key }});
```
