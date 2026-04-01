# Fix: access_optimization

Add indexes to tables that lack them.

## Context

PostgreSQL indexes are the primary mechanism for access optimization. Unlike Snowflake's clustering keys, indexes are separate data structures that must be explicitly created and are immediately effective once built.

Choose index type and columns based on query patterns:

- **B-tree** (default) — Best for equality and range predicates (`=`, `<`, `>`, `BETWEEN`, `ORDER BY`). Suitable for most columns.
- **BRIN** — Best for large, physically ordered tables (e.g., append-only time-series with a timestamp column). Much smaller than B-tree but only effective when physical row order correlates with column values.

Good candidates for indexing:
- Foreign key columns used in joins
- Columns used in `WHERE` clauses
- Date/timestamp columns used in range filters
- Columns used in `ORDER BY`

Use `CREATE INDEX CONCURRENTLY` in production to avoid locking the table during index creation. This takes longer but does not block reads or writes.

## SQL

### B-tree index (default, most common)

```sql
CREATE INDEX CONCURRENTLY idx_{{ asset }}_{{ column }}
ON {{ schema }}.{{ asset }} ({{ column }})
```

### BRIN index (for large, naturally ordered tables)

```sql
CREATE INDEX CONCURRENTLY idx_{{ asset }}_{{ column }}_brin
ON {{ schema }}.{{ asset }} USING brin ({{ column }})
```

### Composite index (multiple columns)

```sql
CREATE INDEX CONCURRENTLY idx_{{ asset }}_{{ columns_slug }}
ON {{ schema }}.{{ asset }} ({{ columns }})
```
