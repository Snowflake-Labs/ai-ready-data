# Fix: incremental_update_coverage

Add tables to publications or create materialized views for incremental processing.

## Context

Two approaches to enabling incremental processing in PostgreSQL:

1. **Add to publication** — enables CDC consumers to receive change events. Requires `wal_level = logical`. Best for tables that feed real-time or near-real-time downstream pipelines.
2. **Create materialized view** — captures a transformed snapshot that can be refreshed. Best for aggregation layers, denormalized reporting tables, or feature stores. Standard PostgreSQL does full rebuilds on `REFRESH`, but this still avoids re-running complex transformation queries against live tables.

## Remediation: Add table to a publication

```sql
ALTER PUBLICATION {{ publication_name }}
ADD TABLE {{ schema }}.{{ asset }}
```

## Remediation: Create a materialized view

```sql
CREATE MATERIALIZED VIEW {{ schema }}.{{ matview_name }} AS
SELECT *
FROM {{ schema }}.{{ asset }}
```

## Remediation: Refresh a materialized view

```sql
REFRESH MATERIALIZED VIEW CONCURRENTLY {{ schema }}.{{ matview_name }}
```
