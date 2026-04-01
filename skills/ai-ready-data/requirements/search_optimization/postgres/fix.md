# Fix: search_optimization

Add GIN or GiST indexes to enable search optimization on tables.

## Context

PostgreSQL does not have a single "search optimization" toggle — you create explicit indexes for the column types and query patterns you need to optimize. The most common search indexes are:

- **GIN on tsvector** — For full-text search using `@@` operator. Requires a `tsvector` column or expression index.
- **GIN on JSONB** — For JSONB containment (`@>`), existence (`?`, `?|`, `?&`), and path queries.
- **GIN on arrays** — For array containment (`@>`, `<@`) and overlap (`&&`) operators.
- **GiST on range types** — For range containment and overlap queries.

Use `CREATE INDEX CONCURRENTLY` in production to avoid locking the table during index creation. Note that `CONCURRENTLY` cannot run inside a transaction block.

## SQL

### Full-text search (GIN on tsvector expression)

```sql
CREATE INDEX CONCURRENTLY idx_{{ asset }}_{{ column }}_fts
ON {{ schema }}.{{ asset }}
USING gin (to_tsvector('english', {{ column }}))
```

### Full-text search (GIN on existing tsvector column)

```sql
CREATE INDEX CONCURRENTLY idx_{{ asset }}_{{ column }}_tsvec
ON {{ schema }}.{{ asset }}
USING gin ({{ column }})
```

### JSONB search (GIN with default jsonb_ops)

```sql
CREATE INDEX CONCURRENTLY idx_{{ asset }}_{{ column }}_jsonb
ON {{ schema }}.{{ asset }}
USING gin ({{ column }})
```

### JSONB search (GIN with jsonb_path_ops for containment only)

```sql
CREATE INDEX CONCURRENTLY idx_{{ asset }}_{{ column }}_jsonb_path
ON {{ schema }}.{{ asset }}
USING gin ({{ column }} jsonb_path_ops)
```

### Array search (GIN)

```sql
CREATE INDEX CONCURRENTLY idx_{{ asset }}_{{ column }}_array
ON {{ schema }}.{{ asset }}
USING gin ({{ column }})
```
