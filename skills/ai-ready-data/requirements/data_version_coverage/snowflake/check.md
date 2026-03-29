# Check: data_version_coverage

Fraction of datasets with Time Travel retention enabled for point-in-time state reconstruction.

## Context

Measures the fraction of base tables in the target schema that have a non-zero `retention_time`, indicating Snowflake Time Travel is active. A score of 1.0 means every base table has Time Travel enabled.

Check measures Time Travel `retention_time > 0`; the diagnostic looks for explicit version columns — these are complementary signals. A table can have Time Travel without a version column, or vice versa.

## SQL

```sql
WITH tables_in_scope AS (
    SELECT
        table_name,
        retention_time
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'BASE TABLE'
),
tables_with_versioning AS (
    SELECT * FROM tables_in_scope
    WHERE retention_time > 0
)
SELECT
    (SELECT COUNT(*) FROM tables_with_versioning) AS tables_with_versioning,
    (SELECT COUNT(*) FROM tables_in_scope) AS total_tables,
    (SELECT COUNT(*) FROM tables_with_versioning)::FLOAT / 
        NULLIF((SELECT COUNT(*) FROM tables_in_scope)::FLOAT, 0) AS value
```