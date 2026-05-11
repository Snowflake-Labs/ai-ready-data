# Fix: search_optimization

Add GIN or GiST indexes to enable search optimization on tables.

## Context

PostgreSQL does not have a single "search optimization" toggle like Snowflake. Instead, search acceleration is achieved by creating GIN or GiST indexes on the appropriate columns. Choose the index type based on the column's data type and query patterns:

- **GIN on `tsvector`** — Full-text search with `@@` operator. Requires a `tsvector` column or expression.
- **GIN on JSONB** — Containment (`@>`), existence (`?`), and path queries on JSONB columns.
- **GIN on arrays** — Overlap (`&&`), containment (`@>`), and `ANY()` queries.
- **GIN with `pg_trgm`** — Trigram-based `LIKE`/`ILIKE` and similarity queries on text columns. Requires the `pg_trgm` extension.
- **GiST on range types** — Range containment, overlap, and adjacency operators.
- **GiST on geometric types** — Spatial queries with `<->`, `&&`, `@>`.

Use `CREATE INDEX CONCURRENTLY` in production to avoid locking the table during index creation.

## SQL

### GIN index on JSONB column

```sql
CREATE INDEX CONCURRENTLY idx_{{ asset }}_{{ column }}_gin
ON {{ schema }}.{{ asset }} USING gin ({{ column }})
```

### GIN index for full-text search

```sql
CREATE INDEX CONCURRENTLY idx_{{ asset }}_{{ column }}_fts
ON {{ schema }}.{{ asset }} USING gin (to_tsvector('english', {{ column }}))
```

### GIN index with trigram support (requires pg_trgm extension)

```sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX CONCURRENTLY idx_{{ asset }}_{{ column }}_trgm
ON {{ schema }}.{{ asset }} USING gin ({{ column }} gin_trgm_ops)
```

### GiST index on range or geometric column

```sql
CREATE INDEX CONCURRENTLY idx_{{ asset }}_{{ column }}_gist
ON {{ schema }}.{{ asset }} USING gist ({{ column }})
```
