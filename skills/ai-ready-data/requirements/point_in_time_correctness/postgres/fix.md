# Fix: point_in_time_correctness

Remediation guidance for tables lacking temporal columns for point-in-time joins.

## Context

Point-in-time correctness prevents future data leakage in ML training pipelines. Tables need temporal columns (`event_time`, `created_at`, `valid_from`/`valid_to`) to support point-in-time joins — queries that reconstruct the state of data as it was known at a specific moment.

PostgreSQL has no native time travel (unlike Snowflake's `AT` / `BEFORE` syntax). Temporal capability relies entirely on explicit timestamp columns and query patterns. The `valid_from` / `valid_to` pattern (SCD Type 2) is the standard approach.

## Remediation: Add an event timestamp column

For tables that record events or facts, add a timestamp column recording when the event occurred:

```sql
ALTER TABLE {{ schema }}.{{ asset }}
    ADD COLUMN IF NOT EXISTS event_time TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP;
```

## Remediation: Add valid_from / valid_to for slowly changing dimensions

For dimension tables that need point-in-time lookups, add temporal range columns:

```sql
ALTER TABLE {{ schema }}.{{ asset }}
    ADD COLUMN IF NOT EXISTS valid_from TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ADD COLUMN IF NOT EXISTS valid_to TIMESTAMPTZ DEFAULT 'infinity';
```

## Remediation: Create an index for temporal queries

Point-in-time joins are range queries on timestamp columns. Add an index to support efficient lookups:

```sql
CREATE INDEX IF NOT EXISTS {{ asset }}_temporal_idx
    ON {{ schema }}.{{ asset }} (event_time);
```

For SCD Type 2 range lookups:

```sql
CREATE INDEX IF NOT EXISTS {{ asset }}_valid_range_idx
    ON {{ schema }}.{{ asset }} (valid_from, valid_to);
```

## Remediation: Backfill timestamps for existing rows

If adding a timestamp to a table with existing data, backfill from the best available proxy:

```sql
UPDATE {{ schema }}.{{ asset }}
SET event_time = {{ proxy_timestamp_expression }}
WHERE event_time IS NULL;
```
