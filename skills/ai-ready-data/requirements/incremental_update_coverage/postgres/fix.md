# Fix: incremental_update_coverage

Add incremental processing capability to tables lacking CDC or materialized view coverage.

## Context

Two remediation paths depending on the use case:

1. **Add to a publication** — enroll the table in a logical replication publication so downstream consumers can process changes incrementally via CDC. Requires `wal_level = logical`.
2. **Create a materialized view** — define a transformation as a materialized view that can be refreshed on demand. Useful for aggregation or denormalization layers.

## Remediation: Add table to a publication

```sql
ALTER PUBLICATION {{ publication_name }} ADD TABLE {{ schema }}.{{ asset }}
```

## Remediation: Create a materialized view

```sql
CREATE MATERIALIZED VIEW {{ schema }}.{{ view_name }} AS
SELECT *
FROM {{ schema }}.{{ asset }}
WITH DATA
```

## Remediation: Refresh a materialized view

```sql
REFRESH MATERIALIZED VIEW CONCURRENTLY {{ schema }}.{{ view_name }}
```

Note: `CONCURRENTLY` requires a unique index on the materialized view. Without it, the refresh takes an exclusive lock.
