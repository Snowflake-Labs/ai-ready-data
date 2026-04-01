# Fix: training_serving_parity

Remediation guidance for feature tables that lack training/serving parity.

## Context

In Snowflake, dynamic tables provide a unified mechanism for both training and serving. PostgreSQL requires separate objects: a materialized view for the batch/training path and a function for the serving/real-time path. True parity means both compute the same transformation logic — this remediation creates the structural scaffolding, but verifying logic equivalence is a manual step.

## Remediation: Create a materialized view for batch/training path

Replace ad-hoc queries with a materialized view that pre-computes the feature transformation:

```sql
CREATE MATERIALIZED VIEW {{ schema }}.{{ asset }}_mv AS
    SELECT * FROM {{ source_query }}
WITH DATA;
```

## Remediation: Create a function for serving/real-time path

Create a function that computes the same feature transformation on demand:

```sql
CREATE OR REPLACE FUNCTION {{ schema }}.{{ asset }}_serve(p_key {{ key_type }})
RETURNS TABLE ({{ return_columns }})
LANGUAGE sql STABLE
AS $$
    SELECT {{ columns }}
    FROM {{ schema }}.{{ asset }}
    WHERE {{ key_column }} = p_key;
$$;
```

## Remediation: Schedule materialized view refresh

Use `pg_cron` to keep the batch path fresh:

```sql
SELECT cron.schedule(
    '{{ asset }}_mv_refresh',
    '0 * * * *',
    $$REFRESH MATERIALIZED VIEW CONCURRENTLY {{ schema }}.{{ asset }}_mv$$
);
```

`CONCURRENTLY` allows reads during refresh but requires a unique index on the materialized view.
