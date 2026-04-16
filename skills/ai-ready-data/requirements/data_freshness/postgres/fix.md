# Fix: data_freshness

Remediation guidance for stale data assets.

## Context

PostgreSQL freshness is tracked via `pg_stat_user_tables` analyze timestamps. Unlike Snowflake's dynamic table `REFRESH`, PostgreSQL does not have a single command to "refresh" a base table — freshness depends on upstream pipelines delivering new data and `ANALYZE` being run.

For materialized views, `REFRESH MATERIALIZED VIEW` updates the data. For base tables, focus on ensuring `ANALYZE` runs regularly and upstream pipelines are operational.

## Remediation: Run ANALYZE on a table

Updates table statistics, which also updates the `last_analyze` timestamp used as the freshness proxy.

```sql
ANALYZE {{ schema }}.{{ asset }};
```

## Remediation: Run ANALYZE on all tables in the schema

```sql
ANALYZE;
```

(Note: `ANALYZE` without arguments analyzes all tables in the database. For schema-scoped analysis, run `ANALYZE` on each table individually.)

## Remediation: Refresh a materialized view

```sql
REFRESH MATERIALIZED VIEW {{ schema }}.{{ asset }};
```

For concurrent refresh (allows reads during refresh):

```sql
REFRESH MATERIALIZED VIEW CONCURRENTLY {{ schema }}.{{ asset }};
```

## Remediation: Configure autovacuum for more frequent analysis

Adjust autovacuum settings to ensure tables are analyzed more frequently:

```sql
ALTER TABLE {{ schema }}.{{ asset }} SET (
    autovacuum_analyze_threshold = 50,
    autovacuum_analyze_scale_factor = 0.05
);
```

## Remediation: Set up scheduled refresh with pg_cron

For automated refresh of materialized views, use `pg_cron`:

```sql
SELECT cron.schedule(
    'refresh_{{ asset }}',
    '0 */{{ refresh_interval_hours }} * * *',
    $$REFRESH MATERIALIZED VIEW CONCURRENTLY {{ schema }}.{{ asset }}$$
);
```
