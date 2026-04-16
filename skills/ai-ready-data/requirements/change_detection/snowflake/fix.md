# Fix: change_detection

Enable change tracking and create streams on tables.

## Context

Two levels of change detection, typically applied together:

1. **Change tracking** — enables Snowflake's internal change tracking on a table. This is lightweight (no additional storage) and is a prerequisite for streams. Enable this first.
2. **Streams** — creates a change data capture stream on a table. Streams record INSERT, UPDATE, DELETE events and are consumed by downstream pipelines. Streams require change tracking to be enabled.

Before creating a stream, check if one already exists:

```sql
SHOW STREAMS LIKE '{{ stream_name }}' IN SCHEMA {{ database }}.{{ schema }};
```

If rows are returned, skip stream creation.

## Fix: Enable change tracking

```sql
ALTER TABLE {{ database }}.{{ schema }}.{{ asset }} SET CHANGE_TRACKING = TRUE
```

## Fix: Create a stream

```sql
CREATE STREAM IF NOT EXISTS {{ database }}.{{ schema }}.{{ stream_name }}
ON TABLE {{ database }}.{{ schema }}.{{ asset }}
```
