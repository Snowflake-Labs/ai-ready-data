# Check: native_format_availability

Fraction of datasets stored in consumption-ready formats without requiring runtime format conversion.

## Context

Classifies tables in `information_schema.tables` as NATIVE (`BASE TABLE`, `DYNAMIC TABLE`) or EXTERNAL (`EXTERNAL TABLE`). The score is the fraction of in-scope tables that are native Snowflake format.

Placeholders: `database`, `schema`.

## SQL

```sql
WITH tables_in_scope AS (
    SELECT
        table_name,
        table_type,
        CASE
            WHEN table_type = 'EXTERNAL TABLE' THEN 'EXTERNAL'
            WHEN table_type IN ('BASE TABLE', 'DYNAMIC TABLE') THEN 'NATIVE'
            ELSE 'OTHER'
        END AS format_type
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type IN ('BASE TABLE', 'DYNAMIC TABLE', 'EXTERNAL TABLE')
)
SELECT
    COUNT_IF(format_type = 'NATIVE') AS native_count,
    COUNT(*) AS total_count,
    COUNT_IF(format_type = 'NATIVE')::FLOAT / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM tables_in_scope
```
