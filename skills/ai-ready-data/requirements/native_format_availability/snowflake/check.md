# Check: native_format_availability

Fraction of in-scope tables that are stored in native Snowflake format (`BASE TABLE` or `DYNAMIC TABLE`) rather than as `EXTERNAL TABLE`.

## Context

External tables require runtime format conversion and cannot use Snowflake's clustering, search optimization, or Time Travel. For AI workloads that require low-latency access, native storage is preferred — but for large archival datasets an external table in Parquet may be acceptable and cheaper. This check measures structural readiness, not desirability.

Returns NULL (N/A) when the schema contains no in-scope tables.

## SQL

```sql
WITH tables_in_scope AS (
    SELECT
        table_name,
        CASE
            WHEN table_type = 'EXTERNAL TABLE' THEN 'EXTERNAL'
            WHEN table_type IN ('BASE TABLE','DYNAMIC TABLE') THEN 'NATIVE'
            ELSE 'OTHER'
        END AS format_type
    FROM {{ database }}.information_schema.tables
    WHERE UPPER(table_schema) = UPPER('{{ schema }}')
        AND table_type IN ('BASE TABLE','DYNAMIC TABLE','EXTERNAL TABLE')
)
SELECT
    COUNT_IF(format_type = 'NATIVE') AS native_count,
    COUNT(*) AS total_count,
    COUNT_IF(format_type = 'NATIVE')::FLOAT / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM tables_in_scope
```
