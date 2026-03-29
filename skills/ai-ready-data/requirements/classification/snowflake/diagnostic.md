# Diagnostic: classification

Per-table breakdown of tag coverage and identification of untagged tables.

## Context

Two diagnostic views:

1. **Tag inventory** — shows every table with its applied tags (or `(no tags)` if none). Use this to understand what classification has been done and identify gaps.
2. **Untagged tables** — lists only tables with no tags at all. Use this as a remediation worklist.

`account_usage.tag_references` has approximately 2-hour latency.

## SQL

### Tag inventory (all tables with their tags)

```sql
SELECT
    t.table_name,
    COALESCE(tr.tag_name, '(no tags)') AS tag_name,
    tr.tag_value
FROM {{ database }}.information_schema.tables t
LEFT JOIN snowflake.account_usage.tag_references tr
    ON UPPER(t.table_name) = UPPER(tr.object_name)
    AND UPPER(t.table_schema) = UPPER(tr.object_schema)
    AND tr.domain = 'TABLE'
    AND UPPER(tr.object_database) = UPPER('{{ database }}')
WHERE t.table_schema = '{{ schema }}'
    AND t.table_type = 'BASE TABLE'
ORDER BY t.table_name, tr.tag_name
```

### Untagged tables only

```sql
SELECT t.table_name
FROM {{ database }}.information_schema.tables t
LEFT JOIN snowflake.account_usage.tag_references tr
    ON UPPER(t.table_name) = UPPER(tr.object_name)
    AND UPPER(t.table_schema) = UPPER(tr.object_schema)
    AND tr.domain = 'TABLE'
    AND UPPER(tr.object_database) = UPPER('{{ database }}')
WHERE t.table_schema = '{{ schema }}'
    AND t.table_type = 'BASE TABLE'
    AND tr.object_name IS NULL
ORDER BY t.table_name
```
