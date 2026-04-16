# Fix: point_in_time_correctness

Add event-timestamp columns to tables that lack them so point-in-time joins can prevent future-data leakage.

## Context

Point-in-time correctness requires every feature table to carry an event-time column describing when each row became true. Training pipelines then join features to labels using `feature_time <= label_time` to avoid leaking data from the future.

Remediation is table-by-table and depends on the source of truth:

- **If the upstream system emits an event timestamp**, propagate it into Snowflake rather than generating a new one.
- **If the table is loaded via pipelines**, add a column populated at load time (`CURRENT_TIMESTAMP()` at ingest, or `METADATA$FILE_LAST_MODIFIED` for `COPY INTO` loads).
- **If the table already has a recorded timestamp but with a non-standard name** (e.g. `modified_on`, `dt`), either rename it or add a comment declaring its temporal role so `temporal_scope_declaration` also passes.

The check looks for column-name patterns like `event_*`, `*_at`, `*_date`, `*_time`, `created_*`, `*timestamp*`. Use one of those conventions when adding new columns so the check detects them automatically.

Snowflake does **not** support `ALTER COLUMN SET DEFAULT`. If the table is loaded via pipelines that cannot be changed, add the column, backfill existing rows with a reasonable estimate (e.g. `load_timestamp`, `METADATA$FILE_LAST_MODIFIED`, or an upstream audit column), and update the ingestion path to populate the column going forward.

## Fix: Add an event-timestamp column

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ asset }}
    ADD COLUMN {{ timestamp_column }} TIMESTAMP_NTZ;
```

## Fix: Backfill the event timestamp from a source system column

Use when an existing column (e.g. `modified_on`, `loaded_at`) holds the correct value:

```sql
UPDATE {{ database }}.{{ schema }}.{{ asset }}
SET {{ timestamp_column }} = {{ source_timestamp_expression }}
WHERE {{ timestamp_column }} IS NULL;
```

## Fix: Backfill from ingestion metadata

Use when the table was loaded via `COPY INTO` and no business timestamp exists. `METADATA$FILE_LAST_MODIFIED` is only populated during the `COPY INTO` itself, so capture it into a scratch column during load or re-ingest to backfill. For already-loaded rows, `CURRENT_TIMESTAMP()` is the least-bad fallback but should be documented as imprecise:

```sql
UPDATE {{ database }}.{{ schema }}.{{ asset }}
SET {{ timestamp_column }} = CURRENT_TIMESTAMP()
WHERE {{ timestamp_column }} IS NULL;
```

## Fix: Document the column

After populating the column, add a comment so it also satisfies `temporal_scope_declaration`:

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ asset }}
    ALTER COLUMN {{ timestamp_column }} SET COMMENT 'Event time: when this row became true in the source system';
```
