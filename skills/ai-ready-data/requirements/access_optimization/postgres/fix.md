# Fix: access_optimization

Add indexes to large tables that lack them.

## Context

Indexes enable the PostgreSQL query planner to avoid sequential scans on large tables, dramatically improving query performance for filtered scans and joins. This is the single most impactful optimization for tables frequently queried by AI workloads.

Choose index columns based on the most common filter and join predicates. Good candidates are:
- Foreign key columns used in joins
- Date/timestamp columns used in range filters
- Low-to-medium cardinality columns used in WHERE clauses

For time-series or append-only data, consider a BRIN index instead of B-tree — BRIN indexes are much smaller and work well when the physical row order correlates with the indexed column.

Use `CREATE INDEX CONCURRENTLY` in production to avoid locking the table during index creation. Note that `CONCURRENTLY` cannot run inside a transaction block.

## SQL

### B-tree index (general purpose)

```sql
CREATE INDEX CONCURRENTLY idx_{{ asset }}_{{ column }}
ON {{ schema }}.{{ asset }} ({{ column }})
```

### BRIN index (time-series / append-only data)

```sql
CREATE INDEX CONCURRENTLY idx_{{ asset }}_{{ column }}_brin
ON {{ schema }}.{{ asset }} USING brin ({{ column }})
```

### Composite index (multi-column filters)

```sql
CREATE INDEX CONCURRENTLY idx_{{ asset }}_composite
ON {{ schema }}.{{ asset }} ({{ column_1 }}, {{ column_2 }})
```
