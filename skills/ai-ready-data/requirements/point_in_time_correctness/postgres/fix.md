# Fix: point_in_time_correctness

Remediation guidance for tables missing temporal columns required for point-in-time joins.

## Context

Point-in-time joins require at least one timestamp column per table that records when a row became valid or when an event occurred. Without these columns, feature pipelines cannot prevent future data leakage during training dataset construction.

## Remediation: Add an event timestamp column

Add a timestamp column that records when each row's data became valid:

```sql
ALTER TABLE {{ schema }}.{{ asset }}
    ADD COLUMN event_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
```

## Remediation: Add validity range columns

For slowly-changing dimension (SCD Type 2) tables, add `valid_from` and `valid_to` columns:

```sql
ALTER TABLE {{ schema }}.{{ asset }}
    ADD COLUMN valid_from TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ADD COLUMN valid_to TIMESTAMP WITH TIME ZONE DEFAULT 'infinity'::TIMESTAMP WITH TIME ZONE;
```

## Remediation: Backfill timestamps from existing data

If the table has a created/modified column under a non-standard name, backfill the new temporal column:

```sql
UPDATE {{ schema }}.{{ asset }}
SET event_time = {{ source_timestamp_column }};
```

## Remediation: Add an index for point-in-time queries

Point-in-time joins filter on timestamp ranges. Add an index to support efficient lookups:

```sql
CREATE INDEX ON {{ schema }}.{{ asset }} (event_time);
```

For validity-range patterns, a GiST index on a tstzrange can accelerate overlap queries:

```sql
ALTER TABLE {{ schema }}.{{ asset }}
    ADD COLUMN validity tstzrange
    GENERATED ALWAYS AS (tstzrange(valid_from, valid_to, '[)')) STORED;

CREATE INDEX ON {{ schema }}.{{ asset }} USING gist (validity);
```
