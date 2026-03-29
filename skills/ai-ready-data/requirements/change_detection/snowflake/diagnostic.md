# Diagnostic: change_detection

Per-table breakdown of change tracking and stream status.

## Context

Two diagnostic views are available:

1. **Change tracking status** — shows whether each table has change tracking enabled. Uses `SHOW TABLES` + `RESULT_SCAN` (must run in the same session).
2. **Stream inventory** — shows all streams in the schema with their source tables, types, and staleness status. Stale streams are no longer consuming changes and need to be recreated or their consumers need to catch up.

## SQL

### Change tracking status

```sql
SHOW TABLES IN SCHEMA {{ database }}.{{ schema }};

SELECT
    "name" AS table_name,
    "rows" AS row_count,
    "change_tracking",
    CASE
        WHEN "change_tracking" = 'ON' THEN 'ENABLED'
        ELSE 'NEEDS ENABLING'
    END AS status
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "kind" = 'TABLE'
ORDER BY "change_tracking" DESC, "name"
```

### Stream inventory

```sql
SHOW STREAMS IN SCHEMA {{ database }}.{{ schema }};

SELECT
    "name" AS stream_name,
    "source_name" AS table_name,
    "type" AS stream_type,
    "stale",
    "stale_after"
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
ORDER BY "source_name", "name"
```
