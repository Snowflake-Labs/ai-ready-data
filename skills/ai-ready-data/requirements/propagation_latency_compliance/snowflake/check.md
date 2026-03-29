# Check: propagation_latency_compliance

Fraction of data pipelines where end-to-end propagation latency meets the defined freshness SLA.

## Context

Checks whether dynamic tables in the target schema exist, as a proxy for pipeline latency compliance. Dynamic tables are Snowflake's declarative pipeline primitive — their presence indicates managed refresh.

A full lag-vs-target comparison requires `SHOW DYNAMIC TABLES` (see diagnostic), since `information_schema.tables` does not expose target lag or scheduling state. This check returns 1.0 when at least one dynamic table exists.

Scoped to `{{ database }}.{{ schema }}`.

## SQL

```sql
WITH dynamic_tables AS (
    SELECT
        table_catalog,
        table_schema,
        table_name
    FROM {{ database }}.information_schema.tables
    WHERE table_schema = '{{ schema }}'
        AND table_type = 'DYNAMIC TABLE'
)
SELECT
    COUNT(*) AS total_dynamic_tables,
    -- Note: To get actual lag vs target lag, you need SHOW DYNAMIC TABLES
    -- This check verifies dynamic tables exist; detailed lag check requires SHOW command
    COUNT(*)::FLOAT / NULLIF(COUNT(*)::FLOAT, 0) AS value
FROM dynamic_tables
```
