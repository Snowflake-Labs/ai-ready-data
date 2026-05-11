# Fix: native_format_availability

Remediation guidance for datasets not in consumption-ready native formats.

## Context

In PostgreSQL, "native format" means using proper typed columns (especially JSONB for structured/semi-structured data) rather than storing JSON in TEXT columns. JSONB provides binary storage, indexing (GIN), containment operators (`@>`), and path queries — TEXT columns require casting on every query and cannot be indexed for JSON operations.

For foreign tables, consider materializing frequently accessed data into native PostgreSQL tables.

## Remediation: Migrate TEXT columns storing JSON to JSONB

First, add a JSONB column, backfill it, then drop the old TEXT column:

```sql
ALTER TABLE {{ schema }}.{{ asset }} ADD COLUMN {{ column }}_jsonb JSONB;

UPDATE {{ schema }}.{{ asset }}
SET {{ column }}_jsonb = {{ column }}::JSONB
WHERE {{ column }} IS NOT NULL AND {{ column }}::JSONB IS NOT NULL;

ALTER TABLE {{ schema }}.{{ asset }} DROP COLUMN {{ column }};
ALTER TABLE {{ schema }}.{{ asset }} RENAME COLUMN {{ column }}_jsonb TO {{ column }};
```

## Remediation: Add a GIN index on JSONB columns

For optimal query performance on JSONB columns:

```sql
CREATE INDEX ON {{ schema }}.{{ asset }} USING GIN ({{ column }});
```

## Remediation: Materialize foreign tables

If external data is stable enough to be materialized:

```sql
CREATE TABLE {{ schema }}.{{ asset }}_native AS
SELECT * FROM {{ schema }}.{{ asset }};
```

Then update downstream references and drop the foreign table.
