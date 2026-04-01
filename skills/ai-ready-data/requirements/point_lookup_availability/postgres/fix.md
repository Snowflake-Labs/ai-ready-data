# Fix: point_lookup_availability

Add primary keys or unique indexes to enable low-latency point lookups.

## Context

Tables without a primary key or unique index cannot serve efficient key-based lookups — the planner must fall back to sequential scans. Adding a primary key is the preferred fix because it communicates uniqueness semantics to both the planner and downstream consumers (ORMs, replication, CDC tools).

Choose key columns that are:
- Naturally unique per row (e.g., `id`, `uuid`, composite business keys)
- NOT NULL (required for primary keys; PostgreSQL enforces this)
- Stable — values should not change after insertion

If the table already has data, adding a primary key will scan the entire table to verify uniqueness and non-nullability. For large tables in production, create the unique index concurrently first, then add the constraint using the existing index to minimize locking.

## SQL

### Add a primary key

```sql
ALTER TABLE {{ schema }}.{{ asset }}
ADD CONSTRAINT {{ asset }}_pkey PRIMARY KEY ({{ column }})
```

### Add a unique index (when PK is not appropriate)

```sql
CREATE UNIQUE INDEX CONCURRENTLY idx_{{ asset }}_{{ column }}_uniq
ON {{ schema }}.{{ asset }} ({{ column }})
```

### Production-safe: create index first, then attach as PK

```sql
CREATE UNIQUE INDEX CONCURRENTLY idx_{{ asset }}_pkey
ON {{ schema }}.{{ asset }} ({{ column }});

ALTER TABLE {{ schema }}.{{ asset }}
ADD CONSTRAINT {{ asset }}_pkey PRIMARY KEY USING INDEX idx_{{ asset }}_pkey;
```

### Composite primary key

```sql
ALTER TABLE {{ schema }}.{{ asset }}
ADD CONSTRAINT {{ asset }}_pkey PRIMARY KEY ({{ column_1 }}, {{ column_2 }})
```
