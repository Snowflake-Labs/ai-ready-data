# Check: data_version_coverage

Fraction of base tables in the schema with Time Travel retention enabled (`retention_time > 0`).

## Context

Measures the fraction of base tables that have a non-zero `retention_time`, indicating Snowflake Time Travel is active. Time Travel enables point-in-time state reconstruction (UNDROP, AT / BEFORE queries) for the configured number of days.

Complementary to `schema_evolution_tracking` (which observes column-history in `ACCOUNT_USAGE.COLUMNS`). A table can have Time Travel without an explicit version column; this check covers the former.

Returns NULL (N/A) when the schema contains no base tables.

## SQL

```sql
SELECT
    COUNT_IF(retention_time > 0) AS tables_with_versioning,
    COUNT(*) AS total_tables,
    COUNT_IF(retention_time > 0)::FLOAT / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM {{ database }}.information_schema.tables
WHERE UPPER(table_schema) = UPPER('{{ schema }}')
    AND table_type = 'BASE TABLE'
```
