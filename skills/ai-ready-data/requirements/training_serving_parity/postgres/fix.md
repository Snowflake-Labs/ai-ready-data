# Fix: training_serving_parity

Remediation guidance for feature tables lacking training/serving parity.

## Context

In Snowflake, dynamic tables serve as the parity mechanism — the same transformation logic drives both batch and real-time paths via auto-refresh. PostgreSQL requires an explicit two-path architecture:

1. **Materialized view** — Batch/training path. Periodically refreshed to provide a consistent snapshot for model training.
2. **Function** — Serving/real-time path. Called at inference time to compute features on demand.

True parity requires that both paths implement identical transformation logic. The materialized view definition and the function body should derive from the same source query.

## Remediation: Create a materialized view for batch training

Replace the static feature table with a materialized view that materializes from the same transformation logic:

```sql
CREATE MATERIALIZED VIEW {{ schema }}.{{ table_name }}_mv AS
    {{ source_query }};
```

## Remediation: Create a serving function for real-time inference

Create a function that computes the same features on demand:

```sql
CREATE OR REPLACE FUNCTION {{ schema }}.get_{{ table_name }}(p_entity_id TEXT)
RETURNS TABLE ({{ column_definitions }})
LANGUAGE sql STABLE
AS $$
    {{ source_query_filtered }}
$$;
```

## Remediation: Schedule materialized view refresh

Use `pg_cron` to refresh the materialized view on a cadence matching the training pipeline:

```sql
SELECT cron.schedule(
    'refresh_{{ table_name }}_mv',
    '0 */1 * * *',
    'REFRESH MATERIALIZED VIEW CONCURRENTLY {{ schema }}.{{ table_name }}_mv'
);
```

`CONCURRENTLY` allows reads during refresh but requires a unique index on the materialized view.
