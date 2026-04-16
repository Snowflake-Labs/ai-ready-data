# Fix: serving_latency_compliance

Remediation guidance for queries exceeding the latency SLA.

## Context

There is no single DDL fix for latency compliance — optimization depends on the specific queries and tables involved. Common PostgreSQL remediation strategies:

1. **Add indexes.** Queries scanning large tables benefit from B-tree indexes on filter/join columns, or GIN indexes for JSONB and full-text search.
2. **Tune work_mem and shared_buffers.** Queries spilling to disk (visible in `temp_blks_written` in `pg_stat_statements`) may benefit from increased `work_mem`.
3. **Materialize expensive subqueries.** If the diagnostic shows repeated slow patterns (e.g., large joins or aggregations), consider pre-computing results into a materialized view.
4. **Partition large tables.** Tables with time-series or high-cardinality data benefit from declarative partitioning.
5. **Review query design.** Anti-patterns like correlated subqueries, missing predicates, or `SELECT *` on wide tables inflate execution time.

## Remediation: Add an index

```sql
CREATE INDEX CONCURRENTLY ON {{ schema }}.{{ asset }} ({{ index_columns }});
```

## Remediation: Create a materialized view for expensive queries

```sql
CREATE MATERIALIZED VIEW {{ schema }}.{{ asset }}_mv AS
{{ query }};

CREATE UNIQUE INDEX ON {{ schema }}.{{ asset }}_mv ({{ key_columns }});
```

## Remediation: Refresh the materialized view

```sql
REFRESH MATERIALIZED VIEW CONCURRENTLY {{ schema }}.{{ asset }}_mv;
```
