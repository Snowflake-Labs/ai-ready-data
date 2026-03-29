# Diagnostic: batch_throughput_sufficiency

Per-load breakdown of recent COPY INTO operations.

## Context

Shows individual load events with rows loaded, rows parsed, error counts, and a status label. Use this to identify which tables or files are producing errors and whether empty loads are occurring.

Status labels: `OK` for clean loads, `ERRORS` for loads with errors_seen > 0, `EMPTY_LOAD` for loads with zero rows, `OTHER` for unexpected statuses.

## SQL

```sql
SELECT
    table_name,
    last_load_time,
    rows_loaded,
    rows_parsed,
    errors_seen,
    status,
    CASE
        WHEN status = 'LOADED' AND errors_seen = 0 THEN 'OK'
        WHEN errors_seen > 0 THEN 'ERRORS'
        WHEN rows_loaded = 0 THEN 'EMPTY_LOAD'
        ELSE 'OTHER: ' || status
    END AS load_status
FROM {{ database }}.information_schema.load_history
WHERE UPPER(schema_name) = UPPER('{{ schema }}')
    AND last_load_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
ORDER BY last_load_time DESC
LIMIT 100
```
