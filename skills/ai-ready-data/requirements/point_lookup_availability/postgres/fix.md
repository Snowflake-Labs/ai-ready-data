# Fix: point_lookup_availability

Add primary keys or unique indexes to enable low-latency point lookups.

## Context

Tables without a primary key or unique index require sequential scans for point lookups, which is prohibitively slow for large tables. Adding a primary key is the strongest guarantee — it enforces uniqueness, non-nullability, and creates a B-tree index in a single operation.

Choose the remediation based on the table's current state:

- **Add primary key** — Best option when a naturally unique, non-null column (or column set) exists. This creates a unique B-tree index and enforces the constraint.
- **Add unique index** — Use when the column(s) are unique but may contain nulls (PostgreSQL unique indexes allow multiple nulls). Also use when you cannot modify the table's constraint definition.
- **Add surrogate key** — Use when no natural key exists. Add a `BIGSERIAL` or `UUID` column as a synthetic primary key.

Adding a primary key on a large table acquires an `ACCESS EXCLUSIVE` lock. For production tables, consider creating the unique index concurrently first, then adding the constraint using the existing index to minimize lock duration.

## SQL

### Add primary key

```sql
ALTER TABLE {{ schema }}.{{ asset }}
ADD CONSTRAINT {{ asset }}_pkey PRIMARY KEY ({{ column }})
```

### Add unique index (non-blocking)

```sql
CREATE UNIQUE INDEX CONCURRENTLY idx_{{ asset }}_{{ column }}_uniq
ON {{ schema }}.{{ asset }} ({{ column }})
```

### Add primary key using existing index (minimal locking)

```sql
CREATE UNIQUE INDEX CONCURRENTLY idx_{{ asset }}_{{ column }}_uniq
ON {{ schema }}.{{ asset }} ({{ column }});

ALTER TABLE {{ schema }}.{{ asset }}
ADD CONSTRAINT {{ asset }}_pkey PRIMARY KEY USING INDEX idx_{{ asset }}_{{ column }}_uniq
```

### Add surrogate key (when no natural key exists)

```sql
ALTER TABLE {{ schema }}.{{ asset }}
ADD COLUMN id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY
```
