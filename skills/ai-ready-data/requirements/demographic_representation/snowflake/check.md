# Check: demographic_representation

Fraction of base tables (or their columns) tagged with a demographic / protected-class attribute.

## Context

Looks for tables or columns tagged with any of the recognized demographic tag names. The tag records that demographic analysis has been considered for this dataset; the check does not measure actual distribution.

`account_usage.tag_references` has approximately 2-hour latency for new tags — recently tagged objects may not appear yet.

Domain is `TABLE` **or** `COLUMN` — a demographic attribute can be declared at the table level or on a single column. Demographic attributes are sensitive — handle with appropriate access controls.

Requires `{{ tag_names }}` — comma-separated quoted list, typically `'demographic','protected_class','sensitive_attribute','fairness_attribute'`.

Returns NULL (N/A) when the schema contains no base tables.

## SQL

```sql
WITH table_count AS (
    SELECT COUNT(*) AS cnt
    FROM {{ database }}.information_schema.tables
    WHERE UPPER(table_schema) = UPPER('{{ schema }}')
        AND table_type = 'BASE TABLE'
),
tagged_tables AS (
    SELECT COUNT(DISTINCT tr.object_name) AS cnt
    FROM snowflake.account_usage.tag_references tr
    JOIN {{ database }}.information_schema.tables t
        ON UPPER(tr.object_name) = UPPER(t.table_name)
        AND UPPER(t.table_schema) = UPPER('{{ schema }}')
        AND t.table_type = 'BASE TABLE'
    WHERE UPPER(tr.object_database) = UPPER('{{ database }}')
        AND UPPER(tr.object_schema)   = UPPER('{{ schema }}')
        AND tr.domain IN ('TABLE','COLUMN')
        AND LOWER(tr.tag_name) IN ({{ tag_names }})
)
SELECT
    tagged_tables.cnt AS tables_tagged,
    table_count.cnt   AS total_tables,
    tagged_tables.cnt::FLOAT / NULLIF(table_count.cnt::FLOAT, 0) AS value
FROM table_count, tagged_tables
```
