# Fix: propagation_latency_compliance

Remediation guidance for pipeline freshness compliance.

## Context

PostgreSQL does not have Snowflake's dynamic tables with declarative target lag. Freshness management requires a combination of materialized views, scheduled refreshes (via `pg_cron` or external schedulers), and documentation.

## Remediation: Create a materialized view for managed refresh

```sql
CREATE MATERIALIZED VIEW {{ schema }}.{{ asset }}_mv AS
SELECT * FROM {{ schema }}.{{ source_table }};
```

## Remediation: Set up scheduled refresh with pg_cron

If the `pg_cron` extension is available, schedule periodic refreshes:

```sql
SELECT cron.schedule(
    '{{ job_name }}',
    '*/5 * * * *',
    $$REFRESH MATERIALIZED VIEW CONCURRENTLY {{ schema }}.{{ asset }}_mv$$
);
```

## Remediation: Document freshness SLA on a table

Add a comment documenting the expected freshness SLA so the check can detect it:

```sql
COMMENT ON TABLE {{ schema }}.{{ asset }} IS 'freshness_sla: {{ sla_interval }}; refresh_interval: {{ refresh_interval }}';
```

## Remediation: Manual refresh of materialized views

```sql
REFRESH MATERIALIZED VIEW CONCURRENTLY {{ schema }}.{{ asset }}_mv;
```

## Remediation: Monitor logical replication lag

For tables replicated via logical replication, check slot lag:

```sql
SELECT
    slot_name,
    confirmed_flush_lsn,
    pg_current_wal_lsn() - confirmed_flush_lsn AS replication_lag_bytes
FROM pg_replication_slots
WHERE slot_type = 'logical';
```
